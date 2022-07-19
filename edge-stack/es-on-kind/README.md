# Edge-Stack on Kind Cluster 
Route and secure traffic to your cluster with a Kubernetes-native API Gateway built on the Envoy Proxy.

# Setup
## Requirements:
1. Clone the project
```shell
git clone https://github.com/vinaykagithapu/k8s-tools.git
cd k8s-tools/edge-stack/es-on-kind
```

2. Setup a kind cluster with 3 worker nodes
```shell
kind create cluster --name es-cluster --image kindest/node:v1.21.1 --config kind.yaml
kubectl get nodes --watch
```

## Install Ambassador Edge Stack
1. Add the repo
```shell
helm repo add datawire https://app.getambassador.io
helm repo update
```

2. Create Namespace and Install:
```shell
kubectl create namespace ambassador && \
kubectl apply -f aes-crds.yaml
kubectl wait --timeout=90s --for=condition=available deployment emissary-apiext -n emissary-system
helm install edge-stack --namespace ambassador datawire/edge-stack --version 8.0.0 -f edge-stack-values.yaml && \
kubectl -n ambassador wait --for condition=available --timeout=90s deploy -lproduct=aes
```
3. Get URL of Edge-Stack
```shell
export NODE_PORT=$(kubectl get --namespace ambassador -o jsonpath="{.spec.ports[1].nodePort}" services edge-stack)
export NODE_IP=$(kubectl get nodes --namespace ambassador -o jsonpath="{.items[0].status.addresses[0].address}")
echo https://$NODE_IP:$NODE_PORT
``` 
4. Copy the URL (clipboard1)

## Routing traffic from the edge
1. Create listener 
```shell
kubectl apply -f listener.yaml
```

2. Create a sample app quote service 
```shell
kubectl apply -f qotm.yaml
kubectl apply -f nginx-app.yaml
```

3. Create quote service mapping
```shell
kubectl apply -f mapping.yaml
```

## Create an OAuth Filter with the credentials
1. Create app registartion in Azure AD, and provide redirect URI as https://$NODE_IP:$NODE_PORT/.ambassador/oauth2/redirection-endpoint as copied in clipboard1.
2. Copy Tenant ID (clipboard2), Client ID (clipboard3), Secret/Token(clipboard3) from Azure AD.
3. Modify the [azure-ad-filter.yaml](azure-ad-filter.yaml) as per above copied values and redirect URI.
4. create oauth filter and filterpolicy
```shell
kubectl apply -f azure-ad-filter.yaml
kubectl apply -f azure-policy.yaml
```

## Access the services via edge-stack
1. Vist the link in browser
```
https://$NODE_IP:$NODE_PORT/app1/
https://$NODE_IP:$NODE_PORT/app2/
```
2. It will redirect to Microsoft Login
3. Login with creds


# CleanUp
```shell
kubectl delete -f azure-policy.yaml
kubectl delete -f azure-ad-filter.yaml
kubectl delete -f mapping.yaml
kubectl delete -f nginx-app.yaml
kubectl delete -f qotm.yaml
kubectl delete -f listener.yaml
helm uninstall edge-stack --namespace ambassador
kubectl delete -f aes-crds.yaml
kubectl delete namespace ambassador
kind delete clusters es-cluster
```
