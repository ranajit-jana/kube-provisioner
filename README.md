# Container and orchestration security
### reva.edu.in Capstone Project



to debug terraform commands
export TF_LOG=DEBUG



kubectl logs --since=3h kube-bench-g6b8z


for connecting to the cluster
```
aws eks --region example_region update-kubeconfig --name cluster_name

```

aws eks --region us-east-1 update-kubeconfig --name my-eks
Setup the Security Hub
aws ecr get-login-password --region us-east-1 | docker login --username kubeuser AWS --password-stdin 471112573492.dkr.ecr.us-east-1.amazonaws.com
aws ecr get-login --no-include-email --region us-east-1 |  

docker login -u AWS -p $(aws ecr get-login-password --region us-east-1) 471112573492.dkr.ecr.us-east-1.amazonaws.com
And


docker tag 98d497e9284b 471112573492.dkr.ecr.us-east-1.amazonaws.com/k8s/kube-bench:0.0.1
docker push 471112573492.dkr.ecr.us-east-1.amazonaws.com/k8s/kube-bench:0.0.1

aws sts get-caller-identity


docker login -u kubeuser https://471112573492.dkr.ecr.us-east-1.amazonaws.com/

adding itfor demo


service docker stop
rm ~/.docker/config.json
service docker start

