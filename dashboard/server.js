const express = require('express');
const path = require('path');
const http = require('http');
const socketIo = require('socket.io');
const k8s = require('@kubernetes/client-node');
const { Pool } = require('pg');

// Initialize Postgres Pool (will use PGHOST, PGUSER, PGPASSWORD, PGDATABASE env vars)
const pool = new Pool();
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});
const port = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname)));
app.use(express.json());

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
const k8sAppsApi = kc.makeApiClient(k8s.AppsV1Api);

// Health Endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'Healthy', 
        uptime: process.uptime(),
        platform: 'Azure AKS'
    });
});

// Scale Endpoint
app.post('/api/scale', async (req, res) => {
    try {
        const { deployment, replicas } = req.body;
        const namespace = 'default';
        const patch = [
            {
                op: 'replace',
                path: '/spec/replicas',
                value: parseInt(replicas, 10)
            }
        ];
        const options = { headers: { 'Content-type': k8s.PatchUtils.PATCH_FORMAT_JSON_PATCH } };
        await k8sAppsApi.patchNamespacedDeployment(deployment, namespace, patch, undefined, undefined, undefined, undefined, undefined, options);
        res.json({ success: true, message: `Scaled ${deployment} to ${replicas} replicas.` });
    } catch (err) {
        console.error('Scaling error:', err);
        res.status(500).json({ success: false, error: err.message });
    }
});

// Database Entry Endpoint
app.post('/api/db/entry', async (req, res) => {
    try {
        const { message } = req.body;
        // Create table if not exists
        await pool.query('CREATE TABLE IF NOT EXISTS dashboard_logs (id SERIAL PRIMARY KEY, message TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
        
        // Insert record
        const result = await pool.query('INSERT INTO dashboard_logs (message) VALUES ($1) RETURNING *', [message]);
        res.json({ success: true, data: result.rows[0] });
    } catch (err) {
        console.error('DB error:', err);
        res.status(500).json({ success: false, error: 'Database connection failed. Ensure PG variables are set.' });
    }
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
    try {
        const data = await getClusterData();
        io.emit("clusterData", data);
    } catch (err) {
        console.error("[FORTRESS-TELEMETRY] Failed to fetch metrics:", err.message);
    }
}, 3000);

io.on('connection', (socket) => {
    console.log('New client connected');
    socket.on('disconnect', () => console.log('Client disconnected'));
});

server.listen(port, '0.0.0.0', () => {
    console.log(`[FORTRESS-CORE] Real-Time API online at port ${port}`);
});
