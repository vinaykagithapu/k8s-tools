# Emissary-ingress in Kind Cluster using Helm
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

## Create Kind Cluster
1. Create kind cluster
```
kind create cluster
```

## Deploy 2 Web Apps
1. Clone the project
```
git clone https://github.com/vinaykagithapu/k8s-tools.git
cd k8s-tools/emissary-ingress/kind
```
2. Deploy nginx-web app and service
```
kubectl apply -f webapp1/deploy-nginx.yaml
```
3. Deploy httpd-web app and service in httpd namespace
```
kubectl apply -f webapp2/deploy-httpd.yaml
```

## Install Emissary-Ingress Using Helm

1. Add datawire helm repo
```
helm repo add datawire https://app.getambassador.io
helm repo update
```
2. Create namespace and install
```
kubectl create namespace emissary && \
kubectl apply -f emissary-crds.yaml
kubectl wait --timeout=90s --for=condition=available deployment emissary-apiext -n emissary-system
helm install emissary-ingress --namespace emissary datawire/emissary-ingress -f emissary-values.yaml && \
kubectl -n emissary wait --for condition=available --timeout=90s deploy -lapp.kubernetes.io/instance=emissary-ingress
```
3. Create listener for all namespaces
```
kubectl apply -f listener.yaml
```
## Mapping Services
1. Mapping can be done in 2 ways, within the service or using mapping 
2. Create mapping resources for two services
```
kubectl apply -f webapp1/mapping-nginx.yaml
kubectl apply -f webapp2/mapping-httpd.yaml
```
3. An example of mapping within the service looks like below
```
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

## Access the web services via emissary-ingress
1. port-forward the emissary-ingress service
```
kubectl -n emissary port-forward service/emissary-ingress 8888:80
```
2. visit the niginx web service 
```
http://127.0.0.1:8888/app1/
```
3. visit the httpd web service 
```
http://127.0.0.1:8888/app2/
```


# Destroy Setup
```
kubectl delete -f webapp2/mapping-httpd.yaml
kubectl delete -f webapp1/mapping-nginx.yaml
kubectl delete -f listener.yaml
helm uninstall emissary-ingress --namespace emissary
kubectl delete -f emissary-crds.yaml
kubectl delete namespace emissary
kubectl delete -f webapp2/deploy-httpd.yaml
kubectl delete -f webapp1/deploy-nginx.yaml
kind delete cluster
```
