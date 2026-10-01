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

### OAuth (`auth.type: k8s_oidc | azure_entra | oidc_client_credentials`)

Instead of a PAT, the worker fetches a short-lived OAuth token and refreshes it automatically. Requires executor image v2.3-cloud or newer, and GMS configured to accept external OAuth tokens (`EXTERNAL_OAUTH_*`; see DataHub's `docs/authentication/external-oauth-providers.md`). An OAuth `auth.type` drops `DATAHUB_GMS_TOKEN`; `tokenFileEnabled` is `pat`-only and fails the render otherwise.

Client secrets never go in values — supply them from a Secret via `extraEnvsFrom` (keys `DATAHUB_AUTH_CLIENT_SECRET` / `DATAHUB_AUTH_AZURE_CLIENT_SECRET`).

```yaml
global:
  datahub:
    auth:
      type: oidc_client_credentials
      audience: https://datahub.example.com   # optional
      oidc:
        tokenEndpoint: https://idp.example.com/oauth2/token
        clientId: datahub-executor
        scope: ""                              # optional
extraEnvsFrom:
  - secretRef:
      name: datahub-executor-oauth             # key: DATAHUB_AUTH_CLIENT_SECRET
```

| Value | Env var | Provider |
| --- | --- | --- |
| `tokenFile` | `DATAHUB_AUTH_TOKEN_FILE` | `k8s_oidc` (optional; defaults to the EKS projected-token path — mount a projected `serviceAccountToken` via `extraVolumes`) |
| `audience` | `DATAHUB_AUTH_AUDIENCE` | `k8s_oidc`, `oidc_client_credentials` (optional) |
| `azure.tenantId` / `clientId` / `scope` | `DATAHUB_AUTH_AZURE_*` | `azure_entra` (client secret optional with workload identity) |
| `oidc.tokenEndpoint` / `clientId` / `scope` | `DATAHUB_AUTH_TOKEN_ENDPOINT` / `CLIENT_ID` / `SCOPE` | `oidc_client_credentials` (`scope` optional) |
