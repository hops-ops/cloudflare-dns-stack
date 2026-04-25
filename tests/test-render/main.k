import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

# ==============================================================================
# Unit tests for cloudflare DNSStack XRD
#
# This stack composes ExternalDNS configured for Cloudflare. cert-manager
# integration (ClusterIssuer + Usage) is optional. ExternalSecrets DX
# composes one ExternalSecret per consumer namespace when enabled.
# ==============================================================================

_items = [
    # ==========================================================================
    # Test 1: Minimal claim renders ExternalDNS Helm Release + ClusterIssuer.
    # Defaults: certManager.enabled=true, externalSecrets.enabled=false.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "minimal-renders-edns-and-cluster-issuer"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "cloudflare.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    domains = [
                        {name = "example.com"}
                    ]
                    clusterIssuer = {
                        email = "admin@example.com"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "dns-edns"
                    spec = {
                        forProvider = {
                            namespace = "external-dns"
                            values = {
                                provider.name = "cloudflare"
                                domainFilters = ["example.com"]
                                env = [{
                                    name = "CF_API_TOKEN"
                                    valueFrom.secretKeyRef = {
                                        name = "cloudflare-api-token"
                                        key = "api-token"
                                    }
                                }]
                            }
                        }
                        providerConfigRef.name = "my-cluster"
                    }
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "dns-cluster-issuer"
                    spec.forProvider.manifest = {
                        apiVersion = "cert-manager.io/v1"
                        kind = "ClusterIssuer"
                        metadata.name = "letsencrypt-prod"
                        spec.acme = {
                            email = "admin@example.com"
                            server = "https://acme-v02.api.letsencrypt.org/directory"
                            privateKeySecretRef.name = "letsencrypt-prod-account-key"
                            solvers = [{
                                dns01.cloudflare.apiTokenSecretRef = {
                                    name = "cloudflare-api-token"
                                    key = "api-token"
                                }
                            }]
                        }
                    }
                }
                {
                    apiVersion = "protection.crossplane.io/v1beta1"
                    kind = "Usage"
                    metadata.name = "dns-delete-cluster-issuer-before-cert-manager"
                    spec.of.resourceRef.name = "cert-manager"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 2: Staging flag swaps the ACME server + ClusterIssuer name.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "staging-flag-switches-server"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "cloudflare.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    clusterIssuer = {
                        email = "admin@example.com"
                        staging = True
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "dns-cluster-issuer"
                    spec.forProvider.manifest = {
                        apiVersion = "cert-manager.io/v1"
                        kind = "ClusterIssuer"
                        metadata.name = "letsencrypt-staging"
                        spec.acme = {
                            server = "https://acme-staging-v02.api.letsencrypt.org/directory"
                            email = "admin@example.com"
                            privateKeySecretRef.name = "letsencrypt-staging-account-key"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 3: certManager.enabled=false skips the integration entirely —
    # no ClusterIssuer, no Usage. ExternalDNS still renders.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "cert-manager-disabled-skips-integration"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "cloudflare.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    certManager = {
                        enabled = False
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "dns-edns"
                }
                {
                    apiVersion = "cloudflare.hops.ops.com.ai/v1alpha1"
                    kind = "DNSStack"
                    metadata.name = "dns"
                    status.ready = False
                }
            ]
        }
    }

    # ==========================================================================
    # Test 4: ExternalSecrets enabled — composes one ExternalSecret per
    # consumer namespace (external-dns + cert-manager).
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "external-secrets-fans-out-to-both-namespaces"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "cloudflare.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    clusterIssuer = {
                        email = "admin@example.com"
                    }
                    externalSecrets = {
                        enabled = True
                        secretStoreRef = {
                            name = "aws-secrets"
                            kind = "ClusterSecretStore"
                        }
                        remoteRef = {
                            key = "prod/cloudflare/api-token"
                            property = "token"
                        }
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "dns-edns-cf-token-eso"
                    spec.forProvider.manifest = {
                        apiVersion = "external-secrets.io/v1"
                        kind = "ExternalSecret"
                        metadata = {
                            name = "cloudflare-api-token"
                            namespace = "external-dns"
                        }
                        spec = {
                            refreshInterval = "1h"
                            secretStoreRef = {
                                name = "aws-secrets"
                                kind = "ClusterSecretStore"
                            }
                            target = {
                                name = "cloudflare-api-token"
                                creationPolicy = "Owner"
                            }
                            data = [{
                                secretKey = "api-token"
                                remoteRef = {
                                    key = "prod/cloudflare/api-token"
                                    property = "token"
                                }
                            }]
                        }
                    }
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "dns-cm-cf-token-eso"
                    spec.forProvider.manifest = {
                        apiVersion = "external-secrets.io/v1"
                        kind = "ExternalSecret"
                        metadata = {
                            name = "cloudflare-api-token"
                            namespace = "cert-manager"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 5: ExternalSecrets enabled + certManager disabled — only the
    # external-dns ExternalSecret is composed (no stray Secret in a
    # cert-manager namespace where cert-manager isn't running).
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "external-secrets-skips-cm-namespace-when-cm-disabled"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "cloudflare.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    certManager = {
                        enabled = False
                    }
                    externalSecrets = {
                        enabled = True
                        secretStoreRef.name = "aws-secrets"
                        remoteRef = {
                            key = "prod/cloudflare/api-token"
                            property = "token"
                        }
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "dns-edns-cf-token-eso"
                    spec.forProvider.manifest.metadata.namespace = "external-dns"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 6: apiToken override flows through to ExternalDNS env, ClusterIssuer
    # solver, and ExternalSecret target name.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "api-token-override-flows-through"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "cloudflare.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    apiToken = {
                        secretName = "cf-token-custom"
                        secretKey = "value"
                    }
                    clusterIssuer = {
                        email = "admin@example.com"
                    }
                    externalSecrets = {
                        enabled = True
                        secretStoreRef.name = "aws-secrets"
                        remoteRef = {
                            key = "prod/cf"
                            property = "token"
                        }
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "dns-edns"
                    spec.forProvider.values.env = [{
                        name = "CF_API_TOKEN"
                        valueFrom.secretKeyRef = {
                            name = "cf-token-custom"
                            key = "value"
                        }
                    }]
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "dns-cluster-issuer"
                    spec.forProvider.manifest.spec.acme.solvers = [{
                        dns01.cloudflare.apiTokenSecretRef = {
                            name = "cf-token-custom"
                            key = "value"
                        }
                    }]
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "dns-edns-cf-token-eso"
                    spec.forProvider.manifest = {
                        metadata.name = "cf-token-custom"
                        spec.target.name = "cf-token-custom"
                        spec.data = [{
                            secretKey = "value"
                            remoteRef = {
                                key = "prod/cf"
                                property = "token"
                            }
                        }]
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 7: Provider config refs propagate.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "provider-config-refs-propagate"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "cloudflare.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    helmProviderConfigRef = {
                        name = "custom-helm"
                        kind = "ClusterProviderConfig"
                    }
                    kubernetesProviderConfigRef = {
                        name = "custom-k8s"
                    }
                    clusterIssuer = {
                        email = "admin@example.com"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "dns-edns"
                    spec.providerConfigRef = {
                        name = "custom-helm"
                        kind = "ClusterProviderConfig"
                    }
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "dns-cluster-issuer"
                    spec.providerConfigRef = {
                        name = "custom-k8s"
                        kind = "ProviderConfig"
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 8: certManager.name override flows to the protection Usage.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "cert-manager-name-override-flows-to-usage"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "cloudflare.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    certManager = {
                        name = "my-custom-cm"
                    }
                    clusterIssuer = {
                        email = "admin@example.com"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "protection.crossplane.io/v1beta1"
                    kind = "Usage"
                    metadata.name = "dns-delete-cluster-issuer-before-cert-manager"
                    spec.of.resourceRef.name = "my-custom-cm"
                }
            ]
        }
    }
]

items = _items
