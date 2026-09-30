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

### GMS token as a mounted file (`auth.type: pat`)

By default the chart injects the access token as the `DATAHUB_GMS_TOKEN` environment variable via `valueFrom.secretKeyRef`. Clusters whose security policies prohibit referencing Secrets from environment variables can present the token as a file instead:

```yaml
global:
  datahub:
    gms:
      url: https://company.acryl.io/gms
      secretRef: datahub-access-token-secret
      secretKey: datahub-access-token-secret-key
    auth:
      type: pat
      tokenFileEnabled: true
```

With `tokenFileEnabled` the Pod spec contains no `secretKeyRef`: the chart mounts the Secret read-only and the worker reads it via `DATAHUB_AUTH_TYPE=pat` / `DATAHUB_AUTH_TOKEN_FILE` (default path `/etc/datahub/auth/token`), re-reading it on rotation — replacing the Secret does not require a pod restart.

If the token file is delivered by other means (Secrets Store CSI driver, Vault agent, `extraVolumes`), set `auth.tokenFile` to its path and the chart mounts nothing:

```yaml
global:
  datahub:
    auth:
      type: pat
      tokenFileEnabled: true
      tokenFile: /vault/secrets/datahub-token
```

`auth.type: pat` without `tokenFileEnabled` keeps the token in the `DATAHUB_GMS_TOKEN` env var (the provider's fallback source) — the same delivery as the default mode, just with the auth mechanism named explicitly.

Requires a worker image whose `acryl-datahub` ships the `pat` token provider (>= 1.7.0.14).
