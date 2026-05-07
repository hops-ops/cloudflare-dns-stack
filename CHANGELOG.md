### What's changed in v0.4.0

* feat: add ExternalDNS Gateway API source alongside Istio (by @patrickleet)

  Adds spec.externalDNS.gatewayApi.enabled (default false). When true,
  ExternalDNS additionally watches Gateway API HTTPRoutes (and their parent
  Gateways for host inheritance) so Knative-on-Gateway-API and any other
  HTTPRoute-fronted services auto-publish per-host DNS records.

  Existing spec.externalDNS.istio.enabled is unchanged. Both toggles are
  independent and additive — useful during a migration period when both
  VirtualServices and HTTPRoutes are in flight.

  Implements [[tasks/dns-stack-gateway-api-source]]


See full diff: [v0.3.0...v0.4.0](https://github.com/hops-ops/cloudflare-dns-stack/compare/v0.3.0...v0.4.0)
