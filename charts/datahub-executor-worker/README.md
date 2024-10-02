## Example usage

```
# Create secret object with GMS access token. Note that secret name and key must match those in values file
$ kubectl create secret generic datahub-access-token-secret --from-literal=datahub-access-token-secret-key=<DATAHUB-ACCESS-TOKEN>

# Deploy executor with executor ID "remote" and GMS URL "https://company.acryl.io/gms"
$ helm install \
  --set global.datahub.executor.executor_id="remote" \
  --set global.datahub.gms.url="https://company.acryl.io/gms" \
    default ./charts/datahub-executor-worker
```
