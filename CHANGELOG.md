### What's changed in v0.2.0

* feat: istio source toggle and platform-default secret store (by @patrickleet)

  Adds spec.externalDNS.istio.enabled (defaults false). When on, ExternalDNS
  also watches istio-virtualservice and istio-gateway sources so Knative-on-
  Istio (and other Istio-routed) services auto-publish per-host DNS records
  without overrideAllValues gymnastics.

  Sources are now computed once in state-init instead of being hard-coded in
  the helm values block with the user's values appended below — this removes
  the duplicate-key YAML pattern that silently dropped overrides.

  Defaults externalSecrets.secretStoreRef.name to "hops-aws-secrets-manager"
  (the platform-wide ClusterSecretStore composed by aws-secret-stack), so
  consumer manifests only declare the AWS Secrets Manager path, not the
  backend reference.


See full diff: [v0.1.2...v0.2.0](https://github.com/hops-ops/cloudflare-dns-stack/compare/v0.1.2...v0.2.0)
