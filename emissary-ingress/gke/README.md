# Emissary-ingress in GKE Cluster with Internal LoadBalancer 
## Emissary-ingress

[Emissary-Ingress](https://www.getambassador.io) is an open-source Kubernetes-native API Gateway +
Layer 7 load balancer + Kubernetes Ingress built on [Envoy Proxy](https://www.envoyproxy.io).
Emissary-ingress is a CNCF incubation project (and was formerly known as Ambassador API Gateway.)

Emissary-ingress enables its users to:
* Manage ingress traffic with [load balancing], support for multiple protocols ([gRPC and HTTP/2], [TCP], and [web sockets]), and Kubernetes integration
* Manage changes to routing with an easy to use declarative policy engine and [self-service configuration], via Kubernetes [CRDs] or annotations
* Secure microservices with [authentication], [rate limiting], and [TLS]
* Ensure high availability with [sticky sessions], [rate limiting], and [circuit breaking]
* Leverage observability with integrations with [Grafana], [Prometheus], and [Datadog], and comprehensive [metrics] support
* Enable progressive delivery with [canary releases]
* Connect service meshes including [Consul], [Linkerd], and [Istio]
* [Knative serverless integration]

See the full list of [features](https://www.getambassador.io/features/) here.

# Architecture

Emissary is configured via Kubernetes CRDs, or via annotations on Kubernetes `Service`s. Internally,
it uses the [Envoy Proxy] to actually handle routing data; externally, it relies on Kubernetes for
scaling and resiliency. For more on Emissary's architecture and motivation, read [this blog post](https://blog.getambassador.io/building-ambassador-an-open-source-api-gateway-on-kubernetes-and-envoy-ed01ed520844).

# Getting Started

## Create GKE Cluster
1. Setup a GKE cluster using web-console/cmd/terraform

## Deploy 2 Web Apps
1. Clone the project
```shell
git clone <url/project>
cd project/gke/
```
2. Deploy nginx-web app and service
```shell
kubectl apply -f webapp1/deploy-nginx.yaml
```
3. Deploy httpd-web app and service in httpd namespace
```shell
kubectl apply -f webapp2/deploy-httpd.yaml
```

## Install Emissary-Ingress Using Helm

1. Add datawire helm repo
```shell
helm repo add datawire https://app.getambassador.io
helm repo update
```
2. Create namespace and install
```shell
kubectl create namespace emissary && \
kubectl apply -f emissary-crds.yaml
kubectl wait --timeout=90s --for=condition=available deployment emissary-apiext -n emissary-system
helm install emissary-ingress --namespace emissary datawire/emissary-ingress -f emissary-values.yaml && \
kubectl -n emissary wait --for condition=available --timeout=90s deploy -lapp.kubernetes.io/instance=emissary-ingress
```
3. Create listener for all namespaces
```shell
kubectl apply -f listener.yaml
```
## Mapping Services
1. Mapping can be done in 2 ways, within the service or using mapping 
2. Create mapping resources for two services
```shell
kubectl apply -f webapp1/mapping-nginx.yaml
kubectl apply -f webapp2/mapping-httpd.yaml
```
3. An example of mapping within the service looks like below
```shell
apiVersion: v1
kind: Service
metadata:
  annotations:
    getambassador.io/config: |-
      ---
      apiVersion: getambassador.io/v3alpha1
      kind: Mapping
      name: web3-mapping
      prefix: /web3/
      #rewrite: /api/
      timeout_ms: 300000
      service: web3-svc:80

```
## Setup Internal Ingress 
1. Create ingress with gcp internal loadbalancer(https), it required ssl certificate. Before create ingress, create ssl certificate and configure it in ingress.yaml file
```shell
kubectl apply -f ingress.yaml
``` 
2. Configure BackendConfig for health checks
```shell
kubectl apply -f backendconfig.yaml
``` 
3. Then edit emissary-ingress.yaml file to add an annotation referencing the BackendConfig and apply the file.
```shell
kubectl edit service/emissary-ingress -n emissary
```
below is the annotation need to add
```shell
cloud.google.com/backend-config: '{"default": "ambassador-hc-config"}'
```

## Access the web services via internal-lb and emissary-ingress
1. Get the ip address of loadbalancer/ingress
```shell
kubectl get ing -n emissary
```
2. visit the niginx web service 
```shell
https://<lb-ipAddress>/app1/
```
3. visit the httpd web service 
```shell
http://<lb-ipAddress>/app2/
```


# Destroy Setup
```shell
kubectl delete -f backendconfig.yaml
kubectl delete -f ingress.yaml
kubectl delete -f webapp2/mapping-httpd.yaml
kubectl delete -f webapp1/mapping-nginx.yaml
kubectl delete -f listener.yaml
helm uninstall emissary-ingress --namespace emissary
kubectl delete -f emissary-crds.yaml
kubectl delete namespace emissary
kubectl delete -f webapp2/deploy-httpd.yaml
kubectl delete -f webapp1/deploy-nginx.yaml
```
