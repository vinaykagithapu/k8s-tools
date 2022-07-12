# Hashicorp Vault on GKE 
## Hashicorp Vault
HashiCorp Vault is an identity-based secrets and encryption management system. A secret is anything that you want to tightly control access to, such as API encryption keys, passwords, and certificates. Vault provides encryption services that are gated by authentication and authorization methods. Using Vault’s UI, CLI, or HTTP API, access to secrets and other sensitive data can be securely stored and managed, tightly controlled (restricted), and auditable.


# Setup
## Requirements:
1. Clone the project
```shell
git clone https://github.com/vinaykagithapu/k8s-tools.git
cd k8s-tools/vault/vault-on-kind
```

2. Setup a kind cluster with 3 worker nodes
```shell
kind create cluster --name vault --image kindest/node:v1.21.1 --config kind.yaml
```

3. Install `kubectl`
```shell
sudo apt install curl -y
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

4. Install `helm`
```shell
curl -LO https://get.helm.sh/helm-v3.8.1-linux-amd64.tar.gz
tar -C /tmp/ -zxvf helm-v3.8.1-linux-amd64.tar.gz
rm helm-v3.8.1-linux-amd64.tar.gz
sudo mv /tmp/linux-amd64/helm /usr/local/bin/helm
sudo chmod +x /usr/local/bin/helm
``` 

5. Add the Helm repositories, so we can access the Kubernetes manifests
```shell
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```

## Storage: Consul
1. We will use a very basic Consul cluster for our Vault backend. </br>
```shell
helm search repo hashicorp/consul --versions

mkdir manifests

helm template consul hashicorp/consul \
  --namespace vault \
  --version 0.39.0 \
  -f consul-values.yaml \
  > ./manifests/consul.yaml
```

2. Deploy the consul services:
```shell
kubectl create ns vault
kubectl -n vault apply -f ./manifests/consul.yaml
kubectl -n vault get pods
```
Wait for 2mins for pods up and running

## TLS End to End Encryption
1. Install requirements
```shell
cd tls
sudo apt-get update && sudo apt-get install -y curl &&
sudo curl -L https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssl_1.6.1_linux_amd64 -o /usr/local/bin/cfssl && \
sudo curl -L https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssljson_1.6.1_linux_amd64 -o /usr/local/bin/cfssljson && \
sudo chmod +x /usr/local/bin/cfssl && \
sudo chmod +x /usr/local/bin/cfssljson
```

2. Generate Self-Signed Certs 
```shell
cfssl gencert -initca ca-csr.json | cfssljson -bare /tmp/ca
cfssl gencert \
  -ca=/tmp/ca.pem \
  -ca-key=/tmp/ca-key.pem \
  -config=ca-config.json \
  -hostname="vault,vault.vault.svc.cluster.local,vault.vault.svc,localhost,127.0.0.1" \
  -profile=default \
  ca-csr.json | cfssljson -bare /tmp/vault
mv /tmp/*.pem .
mv /tmp/*.csr .
cd ..
```

3. Create the TLS secret 
```shell
kubectl -n vault create secret tls tls-ca \
 --cert ./tls/ca.pem  \
 --key ./tls/ca-key.pem

kubectl -n vault create secret tls tls-server \
  --cert ./tls/vault.pem \
  --key ./tls/vault-key.pem
```

## Deploy Vault 
1. Grab the YAML 
```shell
helm search repo hashicorp/vault --versions
helm template vault hashicorp/vault \
  --namespace vault \
  --version 0.19.0 \
  -f vault-values.yaml \
  > ./manifests/vault.yaml
```

2. Deploy the Vault services
```shell
kubectl -n vault apply -f ./manifests/vault.yaml
kubectl -n vault get pods
```
Wait for 2mins for pods up and running

## Initialising Vault
1. Initialize the vault and save the unseal keys & token securly.
2. Need to unseal 3 times and for 3 pods vault-0, vault-1, vault-2
```shell
kubectl -n vault exec -it vault-0 -- sh
kubectl -n vault exec -it vault-1 -- sh
kubectl -n vault exec -it vault-2 -- sh

vault operator init
vault operator unseal

kubectl -n vault exec -it vault-0 -- vault status
kubectl -n vault exec -it vault-1 -- vault status
kubectl -n vault exec -it vault-2 -- vault status
exit
```

## Web UI
1. Checkout the web UI:
```shell
kubectl -n vault get svc
kubectl -n vault port-forward svc/vault-ui 9999:8200
```
2. Now we can access the web UI [here]("https://localhost:9999/")
3. Login with token that we have copied earlier

## Enable Kubernetes Authentication
1. For the injector to be authorised to access vault, we need to enable K8s auth
```shell
kubectl -n vault exec -it vault-0 -- sh 

vault login
# Provide the token that we have copied earlier
vault auth enable kubernetes

vault write auth/kubernetes/config \
token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
kubernetes_host=https://${KUBERNETES_PORT_443_TCP_ADDR}:443 \
kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
issuer="https://kubernetes.default.svc.cluster.local"
exit
```

# Example
## Secret Injection into a Pod
1. In order for us to start using secrets in vault, we need to setup a policy.
```shell
#Create a role for our app

kubectl -n vault exec -it vault-0 -- sh 

vault write auth/kubernetes/role/basic-secret-role \
   bound_service_account_names=basic-secret \
   bound_service_account_namespaces=example-app \
   policies=basic-secret-policy \
   ttl=1h
```

2. The above maps our Kubernetes service account, used by our pod, to a policy.
3. Now lets create the policy to map our service account to a bunch of secrets
```shell
cat <<EOF > /home/vault/app-policy.hcl
path "secret/basic-secret/*" {
  capabilities = ["read"]
}
EOF
vault policy write basic-secret-policy /home/vault/app-policy.hcl
```

4. Now our service account for our pod can access all secrets under `secret/basic-secret/*`
```shell
vault secrets enable -path=secret/ kv
vault kv put secret/basic-secret/helloworld username=dbuser password=sUp3rS3cUr3P@ssw0rd
exit
```

5. Deploy app and see if it works:
```shell
kubectl create ns example-app
kubectl -n example-app apply -f ./example-apps/basic-secret/deployment.yaml
kubectl -n example-app get pods
```

6. Once the pod is ready, the secret is injected into the pod at the following location:
```shell
kubectl -n example-app exec <pod-name> -- sh -c "cat /vault/secrets/helloworld"
```

# Cleanup
```shell
kubectl -n example-app delete -f ./example-apps/basic-secret/deployment.yaml
kubectl delete ns example-app
kubectl -n vault delete -f ./manifests/vault.yaml
kubectl -n vault delete secret tls-server tls-ca
rm tls/*.pem tls/*.csr
kubectl -n vault delete -f ./manifests/consul.yaml
kubectl delete ns vault

```

