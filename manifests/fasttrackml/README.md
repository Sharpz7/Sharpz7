```bash
kubectl create secret generic fml-secrets --from-literal=FML_USERNAME='your_username' --from-literal=FML_PASSWORD='your_password'

kubectl apply -f https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/fasttrackml/deployment.yaml
```