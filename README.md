# cloudflare-dns-stack

Deploys ExternalDNS configured for Cloudflare and (optionally) the cert-manager DNS-01 ClusterIssuer integration. cert-manager itself is **not** installed by this stack — pair with a separate cert-manager install when `certManager.enabled` is true.

When `externalSecrets.enabled` is true, the stack composes one `ExternalSecret` per consumer namespace (external-dns + cert-manager) so the Cloudflare API token can flow from a backend (AWS Secrets Manager, Vault, etc.) into the K8s Secrets that ExternalDNS and cert-manager read.

## Why DNSStack?

**Without it:**
- Hand-rolled ExternalDNS Helm release + Cloudflare provider config
- Manual Secret creation in two namespaces (or copy-paste ExternalSecrets per namespace)
- Manual ClusterIssuer with the Cloudflare DNS-01 solver
- Manual deletion-ordering between the ClusterIssuer and the cert-manager Helm release

**With it:**
- One claim, opinionated defaults, fan-out of ExternalSecrets to the right namespaces
- Single source of truth for the Cloudflare token Secret name + key
- Drop-in cert-manager integration that respects deletion order

## Cloudflare API token

ExternalDNS reads the token from a K8s Secret in its namespace; cert-manager reads the same logical token from a Secret in the cert-manager namespace. Both default to:

- Name: `cloudflare-api-token`
- Key:  `api-token`

Override via `spec.apiToken`.

The token must be a Cloudflare API **token** (not the legacy Global API Key). Required permissions:

- **Zone → DNS → Edit** (for ExternalDNS record management and cert-manager DNS-01 challenges)
- **Zone → Zone → Read**

## ExternalSecrets DX

Set `spec.externalSecrets.enabled: true`, point at a `SecretStore` / `ClusterSecretStore`, and provide one `remoteRef` (key + optional property). The stack composes:

- An `ExternalSecret` in the ExternalDNS namespace targeting the apiToken Secret name + key
- An `ExternalSecret` in the cert-manager namespace (only if `certManager.enabled`) targeting the same Secret name + key

You provide one backend pointer; the stack distributes to both namespaces.

```yaml
spec:
  externalSecrets:
    enabled: true
    secretStoreRef:
      name: aws-secrets
      kind: ClusterSecretStore
    remoteRef:
      key: prod/cloudflare/api-token
      property: token
    refreshInterval: 1h
```

Bring your own Secret instead by leaving `externalSecrets.enabled: false` (the default).

## cert-manager integration

`spec.certManager.enabled` (default `true`) gates the Cloudflare DNS-01 ClusterIssuer + a `protection.crossplane.io.Usage` that holds the external cert-manager Helm Release until this ClusterIssuer is deleted.

The Usage references a Helm Release by name. Default: `cert-manager` (matches `aws-cert-stack`'s `spec.releaseName` default). Override via `spec.certManager.name` if your install uses a different Release name.

If cert-manager isn't Crossplane-managed, the Usage references a non-existent resource and won't reach Ready — install cert-manager via a Crossplane-managed path (e.g. `aws-cert-stack`) for the ordering guarantee, or set `certManager.enabled: false` to skip the integration.

## The Journey

### Stage 1: Minimal

Bring your own Cloudflare API token Secret in the external-dns and cert-manager namespaces; the stack assumes it exists.

```yaml
apiVersion: cloudflare.hops.ops.com.ai/v1alpha1
kind: DNSStack
metadata:
  name: dns
  namespace: default
spec:
  clusterName: my-cluster
  domains:
  - name: example.com
  clusterIssuer:
    email: admin@example.com
```

### Stage 2: With ExternalSecrets

Token lives in AWS Secrets Manager (or another ESO backend); the stack populates both namespaces from one ref.

```yaml
apiVersion: cloudflare.hops.ops.com.ai/v1alpha1
kind: DNSStack
metadata:
  name: dns
  namespace: default
spec:
  clusterName: my-cluster
  domains:
  - name: example.com
  clusterIssuer:
    email: admin@example.com
  externalSecrets:
    enabled: true
    secretStoreRef:
      name: aws-secrets
      kind: ClusterSecretStore
    remoteRef:
      key: prod/cloudflare/api-token
      property: token
```

### Stage 3: Skip the cert-manager integration

For clusters without cert-manager (or where TLS comes from somewhere else):

```yaml
apiVersion: cloudflare.hops.ops.com.ai/v1alpha1
kind: DNSStack
metadata:
  name: dns
  namespace: default
spec:
  clusterName: my-cluster
  domains:
  - name: example.com
  certManager:
    enabled: false
```

## Composed Resources

- `Helm Release (external-dns)` — ExternalDNS configured for Cloudflare; reads `CF_API_TOKEN` from the configured Secret
- `Kubernetes Object (ExternalSecret)` — one per consumer namespace, only when `externalSecrets.enabled: true`
- `Kubernetes Object (ClusterIssuer)` — Let's Encrypt ACME issuer with Cloudflare DNS-01 solver, only when `certManager.enabled: true`
- `protection.Usage` — holds the external cert-manager Helm Release until the ClusterIssuer is deleted, only when `certManager.enabled: true`

## Configuration Reference

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `clusterName` | Yes | - | Target cluster name (drives provider config defaults) |
| `apiToken.secretName` | No | `cloudflare-api-token` | K8s Secret holding the Cloudflare API token |
| `apiToken.secretKey` | No | `api-token` | Key within the Secret |
| `domains[].name` | No | `[]` | Limit ExternalDNS to these zones (populates `domainFilters`) |
| `helmProviderConfigRef.name` | No | `clusterName` | Helm ProviderConfig |
| `kubernetesProviderConfigRef.name` | No | `clusterName` | Kubernetes ProviderConfig |
| `externalDNS.enabled` | No | `true` | Compose the ExternalDNS Helm release |
| `externalDNS.namespace` | No | `external-dns` | Namespace for ExternalDNS |
| `externalDNS.values` | No | `{}` | Helm values merged on top of defaults |
| `externalDNS.overrideAllValues` | No | `{}` | Replace all default Helm values |
| `certManager.enabled` | No | `true` | Render the cert-manager integration |
| `certManager.name` | No | `cert-manager` | metadata.name of the external cert-manager Release (for the protection Usage) |
| `certManager.namespace` | No | `cert-manager` | Namespace where cert-manager runs |
| `clusterIssuer.enabled` | No | `true` | Create the ClusterIssuer (within the integration) |
| `clusterIssuer.email` | No | - | Let's Encrypt registration email |
| `clusterIssuer.staging` | No | `false` | Use staging ACME server |
| `externalSecrets.enabled` | No | `false` | Compose ExternalSecret resources for the apiToken |
| `externalSecrets.secretStoreRef.name` | When enabled | - | SecretStore / ClusterSecretStore name |
| `externalSecrets.secretStoreRef.kind` | No | `ClusterSecretStore` | `SecretStore` or `ClusterSecretStore` |
| `externalSecrets.remoteRef.key` | When enabled | - | Backend key |
| `externalSecrets.remoteRef.property` | No | - | Property within the backend secret (when applicable) |
| `externalSecrets.refreshInterval` | No | `1h` | How often the ExternalSecret refreshes |

## Development

```bash
make render          # Render all examples
make validate        # Validate all examples
make test            # Run unit tests
```

## License

Apache-2.0
