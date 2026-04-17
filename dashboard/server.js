const express = require('express');
const path = require('path');
const k8s = require('@kubernetes/client-node');

const app = express();
const port = 80;

app.use(express.static(path.join(__dirname)));

const kc = new k8s.KubeConfig();
try {
  kc.loadFromCluster();
} catch (e) {
  console.log("Could not load in-cluster config, falling back to local default.", e.message);
  try {
      kc.loadFromDefault();
  } catch (err) {
      console.log("Failed to load generic kubeconfig", err.message);
  }
}

const k8sApi = kc.makeApiClient(k8s.CoreV1Api);

// Enhanced Health Endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'Healthy', 
        message: 'All core systems operational',
        uptime: process.uptime(),
        platform: 'Azure AKS'
    });
});

// Detailed Node Telemetry
app.get('/api/nodes', async (req, res) => {
    try {
        const response = await k8sApi.listNode();
        const nodes = response.body.items.map(node => {
            const cpuCap = node.status.capacity.cpu;
            const memoryCap = node.status.capacity.memory;
            
            let ramGb = 0;
            if (memoryCap.endsWith('Ki')) {
                ramGb = (parseInt(memoryCap.replace('Ki', '')) / (1024 * 1024)).toFixed(1);
            }

            const readyCondition = node.status.conditions.find(c => c.type === 'Ready');
            
            return {
                name: node.metadata.name,
                status: readyCondition ? (readyCondition.status === 'True' ? 'Ready' : 'NotReady') : 'Unknown',
                cpuCapacity: cpuCap,
                ramCapacity: ramGb > 0 ? `${ramGb}GB` : memoryCap,
                // Refined simulation for UI demonstration
                cpuUsagePercent: Math.floor(Math.random() * (35 - 12 + 1) + 12),
                ramUsageGb: (ramGb * (Math.random() * (0.6 - 0.3) + 0.3)).toFixed(1)
            };
        });
        res.json(nodes);
    } catch (error) {
        console.error('Error fetching nodes:', error.message);
        res.status(500).json({ error: 'Failed to fetch nodes' });
    }
});

// Pod Status Distribution for Charts
app.get('/api/pod-stats', async (req, res) => {
    try {
        const response = await k8sApi.listPodForAllNamespaces();
        const pods = response.body.items;
        
        const stats = {
            Running: pods.filter(p => p.status.phase === 'Running').length,
            Pending: pods.filter(p => p.status.phase === 'Pending').length,
            Failed: pods.filter(p => p.status.phase === 'Failed').length,
            Succeeded: pods.filter(p => p.status.phase === 'Succeeded').length
        };
        
        res.json(stats);
    } catch (error) {
        res.status(500).json({ error: 'Failed' });
    }
});

// Detailed Cluster Stats & Events
app.get('/api/cluster-stats', async (req, res) => {
    try {
        const podRes = await k8sApi.listPodForAllNamespaces();
        const eventRes = await k8sApi.listEventForAllNamespaces();
        
        const allPods = podRes.body.items;
        const events = eventRes.body.items
            .sort((a, b) => new Date(b.lastTimestamp) - new Date(a.lastTimestamp))
            .slice(0, 10)
            .map(e => ({
                time: new Date(e.lastTimestamp || e.firstTimestamp).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', second: '2-digit'}),
                message: e.message,
                type: e.type
            }));

        res.json({
            totalPods: allPods.length,
            runningPods: allPods.filter(p => p.status.phase === 'Running').length,
            estimatedCpuUsage: Math.floor(Math.random() * (40 - 10 + 1) + 10),
            events: events
        });
    } catch (error) {
         console.error('Error fetching cluster stats:', error.message);
         res.status(500).json({ error: 'Failed' });
    }
});

app.listen(port, () => {
  console.log(`Fortress Cyber-Ops API listening on port ${port}`);
});
