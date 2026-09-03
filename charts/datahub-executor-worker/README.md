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

### Restricted security context

`securityContext` and `podSecurityContext` are passed through to the worker container/pod. Example for clusters that require non-root, no privilege escalation, RuntimeDefault seccomp, and dropped capabilities:

```yaml
podSecurityContext:
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
securityContext:
  allowPrivilegeEscalation: false
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  capabilities:
    drop:
      - ALL
  seccompProfile:
    type: RuntimeDefault
```

Do not enable `extraCaCerts` under those policies (the CA init container is privileged and runs as root). Avoid `readOnlyRootFilesystem: true` unless `/tmp` is a writable volume.

### PAT without `secretKeyRef`

By default `DATAHUB_GMS_TOKEN` is injected with `valueFrom.secretKeyRef`. To mount the same Kubernetes Secret as a file and load it at startup instead:

```yaml
global:
  datahub:
    gms:
      secretRef: datahub-access-token-secret
      secretKey: datahub-access-token-secret-key
      tokenFile:
        enabled: true
```

The worker still receives `DATAHUB_GMS_TOKEN` in process environment after startup; it is not present as a `secretKeyRef` on the Pod spec. Set `secretRef: ""` (and leave `tokenFile.enabled: false`) if you inject the token yourself via `extraEnvs` / `extraVolumes`.
