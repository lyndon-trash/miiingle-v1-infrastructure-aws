# Miiingle.NET - AWS Terraform Script
Terraform Script for Setting up the AWS Infrastructure

## One-time Setup
- install terraform
```
choco install terraform
terraform init
```
- install the [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
- install [IAM Authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)
```
curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/aws-iam-authenticator
chmod +x ./aws-iam-authenticator
mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
```

## Prepare a Plan
```
terraform plan -out .terraform/plan -var-file="local.tfvars"
```

## Apply the Plan
```
terraform apply ".terraform/plan"
```

## Setup kubectl
```
aws eks --region us-east-1 update-kubeconfig --name <cluster name>
```

## Setup the Metrics Server
```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml

//verify:
kubectl get deployment metrics-server -n kube-system
```

## Setup Autoscaling NodeGroups
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"
kubectl -n kube-system edit deployment.apps/cluster-autoscaler
```
```
    spec:
      containers:
      - command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
------------------------------------- MODIFY --------------------------
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/<YOUR CLUSTER NAME>
        - --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false
------------------------------------- MODIFY --------------------------
```

## [Danger] Destroy the Infrastructure
```
terraform destroy
```