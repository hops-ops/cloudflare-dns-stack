### What's changed in v0.5.0

* feat: wildcardCertificate field for platform Gateway TLS (by @patrickleet)

  Add a typed wildcardCertificate.{enabled, namespace, issuerRef, renewBefore, domains[]}
  field that composes one cert-manager.io/v1 Certificate per domain entry. Default
  namespace is istio-ingress (where platform Gateway resolves listener
  certificateRefs); default issuerRef is the ClusterIssuer composed by this stack.

  Each entry produces "*.<domain>" — apex wildcards (ops.com.ai → covers
  auth.ops.com.ai, web.ops.com.ai) and per-cluster wildcards
  (patlocal.ops.com.ai) compose with the same shape. Verified end-to-end on
  pat-local: LE prod cert issued via DNS-01 in ~30s, platform Gateway listener
  Programmed, https://auth.ops.com.ai serves through SNI longest-match alongside
  Knative's per-route kni-* listeners with no conflict.


See full diff: [v0.4.0...v0.5.0](https://github.com/hops-ops/cloudflare-dns-stack/compare/v0.4.0...v0.5.0)
