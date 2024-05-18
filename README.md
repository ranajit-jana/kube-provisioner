# Container and orchestration security
### reva.edu.in Capstone Project



to debug terraform commands
export TF_LOG=DEBUG



kubectl logs --since=3h kube-bench-g6b8z


for connecting to the cluster
```
aws eks --region example_region update-kubeconfig --name cluster_name

```


Setup the Security Hub
aws ecr get-login-password --region us-east-1 | docker login --username kubeuser AWS --password-stdin 471112573492.dkr.ecr.us-east-1.amazonaws.com


docker login -u AWS -p $(aws ecr get-login-password --region us-east-1) 471112573492.dkr.ecr.us-east-1.amazonaws.com
And


aws sts get-caller-identity


docker login -u kubeuser https://471112573492.dkr.ecr.us-east-1.amazonaws.com/