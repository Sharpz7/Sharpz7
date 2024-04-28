```bash
kubectl create secret generic fml-secrets --from-literal=FML_USERNAME='your_username' --from-literal=FML_PASSWORD='your_password'

kubectl apply -f https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/fasttrackml/deployment.yaml
```

# Testing

```python
import os
import random

import mlflow

# Set the tracking URI to the FastTrackML server
mlflow.set_tracking_uri("https://fml.mcaq.me/")

os.environ["MLFLOW_TRACKING_USERNAME"] = "XXX"
os.environ["MLFLOW_TRACKING_PASSWORD"] = "XXX"

# Set the experiment name
mlflow.set_experiment("my-first-experiment")

# Start a new run
with mlflow.start_run():
    # Log a parameter
    mlflow.log_param("param1", random.randint(0, 100))

    # Log a metric
    mlflow.log_metric("foo", random.random())
    # metrics can be updated throughout the run
    mlflow.log_metric("foo", random.random() + 1)
    mlflow.log_metric("foo", random.random() + 2)

```