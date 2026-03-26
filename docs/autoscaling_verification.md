# Verification Guide: AKS Autoscaling

This guide provides step-by-step instructions to verify that both **Horizontal Pod Autoscaling (HPA)** and **Cluster Autoscaling (CA)** are working correctly in your AKS environment.

## 1. Verify Horizontal Pod Autoscaler (HPA)

HPA scales the number of pod replicas based on CPU or memory utilization.

### Check HPA Status
Run the following command to see your HPA's current status:
```bash
kubectl get hpa
```
You should see `fortress-hpa` with a target utilization (e.g., `0%/50%`) and the current number of replicas.

### Simulate Load for HPA
To test if it scales up, generate CPU load using a temporary Ubuntu pod:
```bash
kubectl run -i --tty load-generator --rm --image=busybox -- /bin/sh -c "while true; do wget -q -O- http://fortress-service; done"
```
*Open a second terminal to monitor the scaling:*
```bash
kubectl get hpa fortress-hpa --watch
```
As the CPU utilization rises above 50%, you will see the `REPLICAS` count increase from 2 towards 5.

---

## 2. Verify Cluster Autoscaler (CA)

Cluster Autoscaler adds or removes nodes in your AKS cluster when pods cannot be scheduled due to resource constraints.

### Check Node Count
First, check the current number of nodes:
```bash
kubectl get nodes
```

### Trigger Cluster Scaling
To trigger the Cluster Autoscaler, you need to create more pods than the current nodes can handle. You can temporarily increase the `maxReplicas` in `hpa.yaml` or scale the deployment manually:
```bash
kubectl scale deployment fortress-web --replicas=20
```
Wait a few minutes and check the node status. Pods will likely be in `Pending` state initially, which triggers the CA to add a new node.

### Monitor CA Activity
You can check the Cluster Autoscaler's status directly:
```bash
kubectl get configmap cluster-autoscaler-status -n kube-system -o yaml
```
Look for `status:` and `ReadableStatus:` in the output to see if it's currently "Scaling" or "Healthy".

---

## 3. Useful Commands for Troubleshooting

- **Describe HPA**: `kubectl describe hpa fortress-hpa`
- **Check Pod Events**: `kubectl get events --sort-by='.lastTimestamp'`
- **View Managed Resource Group Nodes**:
  ```bash
  az aks show --resource-group YOUR_RG --name YOUR_AKS_NAME --query "agentPoolProfiles[0].count"
  ```
