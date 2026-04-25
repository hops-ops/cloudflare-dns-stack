# Changelog

## [0.1.0] - 2026-04-25

Initial release.

### Added

- ExternalDNS Helm Release configured for Cloudflare. The pod reads `CF_API_TOKEN` from a K8s Secret (default name `cloudflare-api-token`, key `api-token`); override via `spec.apiToken`.
- Optional cert-manager DNS-01 ClusterIssuer integration (`spec.certManager.enabled: true`, default). Composes a Let's Encrypt ClusterIssuer wired to the Cloudflare API token Secret plus a `protection.crossplane.io.Usage` that holds the external cert-manager Helm Release until the ClusterIssuer is deleted. This stack does NOT install cert-manager.
- Optional ExternalSecrets DX (`spec.externalSecrets.enabled: true`). One user-supplied backend ref fans out to ExternalSecret resources in both the external-dns and cert-manager namespaces.
- `spec.domains[]` populates ExternalDNS `domainFilters`.
- `spec.clusterIssuer` controls ClusterIssuer name, email, staging flag, and ACME server.
- `spec.certManager.name` (default `cert-manager`) overrides the external Helm Release name the protection Usage references — match this to your cert-manager install if it uses a non-default name.
