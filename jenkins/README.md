# Provision Jenkins in K8s using Terraform 
## Jenkins
Jenkins is an open source automation server. It helps automate the parts of software development related to building, testing, and deploying, facilitating continuous integration and continuous delivery. 
## Terraform
Terraform is an infrastructure as code (IaC) tool that allows you to build, change, and version infrastructure safely and efficiently. 

# Setup
## Jenkins Deployment Using Terraform
1. Clone the project
```
git clone https://github.com/vinaykagithapu/k8s-tools.git
cd k8s-tools/jenkins/
```
2. Create private key and certificate 
```
openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out certificate.pem
```
3. Configure project, kube-config path, config_context in io.tf
4. Initialize - Install the plugins Terraform needs to manage the infrastructure.
5. Plan - Preview the changes Terraform will make to match the configuration.
6. Apply - Make the planned changes. 
```
terraform init
terraform plan
terraform apply
```
## Access Jenkins Web-UI
1. Wait for 5mins and get the Ingress IP address
```
kubectl get ing jenkins -n jenkins
```
2. Configure DNS, pointing Ingress IP to domain
```
[Info] jenkins.hackwithv.com -> x.x.x.x
[Ex]   jenkins.hackwithv.com -> 192.168.0.6
```
3. Access Jenkins Web-UI : https://jenkins.hackwithv.com
4. Username : admin
5. Get temp password: 
```
kubectl get secret --namespace jenkins jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 --decode && echo 
```
6. Change the password: Dashboard > People > User ID > Configure > Password > Save

## Destroy Jenkins Setup
```
terraform destroy
```