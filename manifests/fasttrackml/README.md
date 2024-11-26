```bash
kubectl create secret generic fml-secrets --from-literal=FML_USERNAME='your_username' --from-literal=FML_PASSWORD='your_password'\
    --from-literal=AWS_SECRET_ACCESS_KEY='your_secret' --from-literal=AWS_ACCESS_KEY_ID='your_key'


kubectl create secret generic minio-credentials \
  --from-literal=MINIO_ROOT_USER=admin \
  --from-literal=MINIO_ROOT_PASSWORD=password123

kubectl apply -f https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/fasttrackml/deployment.yaml
```

# Testing

```python
import os
import random

import mlflow
import mlflow.artifacts
from mlflow import create_experiment, get_experiment_by_name, set_experiment

EXPERIMENT_NAME = "fml-testing"

BUCKET_NAME = "fml-artifacts"

mlflow.set_tracking_uri("https://fml.mcaq.me/")

os.environ["AWS_ACCESS_KEY_ID"] = os.getenv("AWS_ACCESS_KEY_ID")
os.environ["AWS_SECRET_ACCESS_KEY"] = os.getenv("AWS_SECRET_ACCESS_KEY")
os.environ["AWS_DEFAULT_REGION"] = "compute-us-1"

os.environ["MLFLOW_TRACKING_USERNAME"] = os.getenv("FML_USER")
os.environ["MLFLOW_TRACKING_PASSWORD"] = os.getenv("FML_PASS")

os.environ["MLFLOW_S3_ENDPOINT_URL"] = "https://s3.mcaq.me"

experiment = get_experiment_by_name(EXPERIMENT_NAME)

experiment_id = (
    experiment.experiment_id
    if experiment
    else create_experiment(
        EXPERIMENT_NAME, artifact_location=f"s3://{BUCKET_NAME}"
    )
)

# Set the experiment as active
set_experiment(experiment_id=experiment_id)

# Start a new run
with mlflow.start_run():
    # Log a parameter
    mlflow.log_param("param1", random.randint(0, 100))

    # Log a metric
    mlflow.log_metric("foo", random.random())
    # metrics can be updated throughout the run
    mlflow.log_metric("foo", random.random() + 1)
    mlflow.log_metric("foo", random.random() + 2)

    print("Run started")

    # Log artifacts
    with open("output.txt", "w") as f:
        f.write("Hello, World!")

    mlflow.log_artifact("output.txt")

    print("Run finished")


```