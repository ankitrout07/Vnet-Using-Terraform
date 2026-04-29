const express = require('express');
const path = require('path');
const http = require('http');
const socketIo = require('socket.io');
const k8s = require('@kubernetes/client-node');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});
const port = 80;

app.use(express.static(path.join(__dirname)));

// Root health check for App Gateway default probes
app.get('/', (req, res) => {
    res.status(200).send('Fortress Dashboard OK');
});

app.get('/health', (req, res) => {
    res.status(200).send('Healthy');
});

const kc = new k8s.KubeConfig();
try {
    kc.loadFromDefault();
} catch (e) {
    try {
        kc.loadFromCluster();
    } catch (err) {
        console.log("Failed to load kubeconfig", err.message);
    }
}

const k8sApi = kc.makeApiClient(k8s.CoreV1Api);

// Health Endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'Healthy', 
        uptime: process.uptime(),
        platform: 'Azure AKS'
    });
});

async function getClusterData() {
    try {
        const [podsRes, nodesRes] = await Promise.all([
            k8sApi.listPodForAllNamespaces(),
            k8sApi.listNode()
        ]);

        const nodes = nodesRes.body.items.map(node => ({
            name: node.metadata.name,
            status: node.status.conditions.find(c => c.type === 'Ready').status === 'True' ? 'Ready' : 'NotReady',
            capacity: 40 // Visual capacity for Tetris grid
        }));

        const pods = podsRes.body.items.map(pod => ({
            name: pod.metadata.name,
            namespace: pod.metadata.namespace,
            status: pod.status.phase,
            node: pod.spec.nodeName,
            type: pod.metadata.namespace === 'kube-system' ? 'system' : 'app'
        }));

        return { nodes, pods };
    } catch (error) {
        console.error('Error fetching cluster data:', error.message);
        return { nodes: [], pods: [] };
    }
}

// Real-time updates via WebSockets
setInterval(async () => {
    const data = await getClusterData();
    io.emit("clusterData", data);
}, 2000);

io.on('connection', (socket) => {
    console.log('New client connected');
    socket.on('disconnect', () => console.log('Client disconnected'));
});

server.listen(port, () => {
  console.log(`Fortress Real-Time API listening on port ${port}`);
});
