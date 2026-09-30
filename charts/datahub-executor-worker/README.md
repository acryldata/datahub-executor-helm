## Example usage

```
# Create secret object with GMS access token. Note that secret name and key must match those in values file
$ kubectl create secret generic datahub-access-token-secret --from-literal=datahub-access-token-secret-key=<DATAHUB-ACCESS-TOKEN>

# Deploy executor with worker ID "remote" and GMS URL "https://company.acryl.io/gms"
$ helm install \
  --set global.datahub.executor.pool_id="remote" \
  --set global.datahub.gms.url="https://company.acryl.io/gms" \
    default ./charts/datahub-executor-worker
```

### GMS token as a mounted file

By default the chart injects the access token as the `DATAHUB_GMS_TOKEN` environment variable via `valueFrom.secretKeyRef`. Clusters whose security policies prohibit referencing Secrets from environment variables can mount the same Secret as a file instead:

```yaml
global:
  datahub:
    gms:
      url: https://company.acryl.io/gms
      secretRef: datahub-access-token-secret
      secretKey: datahub-access-token-secret-key
      tokenFile:
        enabled: true
```

With `tokenFile.enabled: true` the Pod spec contains no `secretKeyRef`: the Secret is mounted read-only at `tokenFile.mountPath` (default `/etc/datahub/auth`) and the worker reads it via `DATAHUB_AUTH_TYPE=pat` / `DATAHUB_AUTH_TOKEN_FILE`. The file is re-read on token rotation, so replacing the Secret does not require a pod restart. Requires a worker image whose `acryl-datahub` ships the `pat` token provider.
