workspace "Michelin Vélo" "Modèle C4 de la plateforme e-commerce Michelin Vélo (hackathon ESGI × Michelin)." {

    !identifiers hierarchical

    model {
        // --- Personnes ---
        client = person "Client" "Achète des produits de la gamme Michelin Vélo."
        admin  = person "Administrateur" "Gère le catalogue, les commandes et le contenu."
        dev    = person "Développeur / DevOps" "Livre le code et opère la plateforme."

        // --- Systèmes externes ---
        cloudflare  = softwareSystem "Cloudflare DNS" "Résolution DNS de *.michelin.shost.fr (DNS-only)." "External"
        letsencrypt = softwareSystem "Let's Encrypt" "Autorité de certification ACME (TLS)." "External"
        github      = softwareSystem "GitHub + GHCR" "Code, CI/CD (Actions) et registre d'images privé." "External"
        azure       = softwareSystem "Microsoft Azure" "AKS, Key Vault, identité managée." "External"

        // --- Système principal ---
        shop = softwareSystem "Plateforme Michelin Vélo" "Boutique e-commerce premium livrée en continu sur AKS." {

            storefront = container "Storefront" "Boutique client." "Next.js (standalone, :3000)"
            backoffice = container "Back-office" "Administration." "Frontend (:80)"
            api        = container "API" "Données, commandes, paiement." "Backend (:8080)"

            apisix     = container "APISIX" "Gateway/ingress unique : terminaison TLS, routage par hôte." "Apache APISIX (Helm)"
            certmgr    = container "cert-manager" "Émet le certificat wildcard Let's Encrypt (DNS-01)." "jetstack (Helm)"
            eso        = container "External Secrets" "Synchronise Azure Key Vault → Secrets Kubernetes." "ESO (Helm)"

            argocd     = container "Argo CD" "Réconciliation GitOps des applications." "argo-cd (Helm)" {
                root       = component "platform-root" "App-of-apps : déclare les ApplicationSets."
                appsetProd = component "ApplicationSet prod" "Liste : storefront / back-office / api → namespace prod."
                appsetPrev = component "ApplicationSet previews" "Générateur Pull Request → namespaces pr-<n>."
                appCtrl    = component "Application Controller" "Sync + selfHeal du cluster vers Git."
                repoServer = component "Repo Server" "Clone le repo GitOps et rend les manifests Helm."
                dex        = component "Dex" "SSO GitHub (membres de l'org)."
            }

            rollouts   = container "Argo Rollouts" "Déploiement progressif canari (25/50/100 %)." "argo-rollouts (Helm)"
            keyvaultDb = container "Azure Key Vault" "Secrets applicatifs + credentials GHCR." "Azure (PaaS)" "Database"
        }

        // --- Relations niveau contexte ---
        client -> shop "Navigue et achète" "HTTPS"
        admin  -> shop "Administre" "HTTPS"
        dev    -> github "Push, Pull Requests" "git"
        dev    -> shop "Opère via Argo CD" "HTTPS"
        shop -> cloudflare "Est résolu via" "DNS"
        shop -> letsencrypt "Obtient ses certificats" "ACME DNS-01"
        shop -> github "Tire images et manifests GitOps" "HTTPS"
        shop -> azure "S'exécute sur / lit ses secrets" "API Azure"

        // --- Relations niveau conteneur ---
        client -> shop.apisix "HTTPS" "443"
        admin  -> shop.apisix "HTTPS" "443"
        dev    -> shop.apisix "Accède à l'UI Argo CD" "HTTPS"

        shop.apisix -> shop.storefront "michelin.shost.fr" "HTTP"
        shop.apisix -> shop.backoffice "admin.michelin.shost.fr" "HTTP"
        shop.apisix -> shop.api "api.michelin.shost.fr" "HTTP"
        shop.apisix -> shop.argocd "argocd.michelin.shost.fr" "HTTP"
        shop.storefront -> shop.api "Appels API" "HTTPS"

        shop.argocd -> shop.storefront "Applique les manifests"
        shop.argocd -> shop.backoffice "Applique les manifests"
        shop.argocd -> shop.api "Applique les manifests"
        shop.argocd -> github "Réconcilie depuis le repo GitOps" "HTTPS"
        shop.rollouts -> shop.api "Pilote le canari"

        shop.certmgr -> letsencrypt "Émet/renouvelle" "ACME DNS-01"
        shop.certmgr -> shop.apisix "Fournit le certificat wildcard"
        shop.eso -> shop.keyvaultDb "Lit les secrets" "Workload Identity"
        shop.eso -> shop.api "Matérialise les Secrets K8s"
        shop.storefront -> github "Pull image" "HTTPS"
        shop.api -> github "Pull image" "HTTPS"
        cloudflare -> shop.apisix "A → IP publique APISIX" "DNS"

        // --- Relations niveau composant (Argo CD) ---
        shop.argocd.root -> shop.argocd.appsetProd "Déclare"
        shop.argocd.root -> shop.argocd.appsetPrev "Déclare"
        shop.argocd.appsetProd -> shop.argocd.appCtrl "Génère les Applications prod"
        shop.argocd.appsetPrev -> shop.argocd.appCtrl "Génère les Applications preview"
        shop.argocd.repoServer -> github "Clone + rend Helm"
        shop.argocd.appCtrl -> shop.argocd.repoServer "Demande les manifests rendus"
        shop.argocd.appCtrl -> shop.api "Applique (sync/selfHeal)"
        dev -> shop.argocd.dex "Login SSO GitHub"

        // --- Environnement de déploiement ---
        deploymentEnvironment "Production" {
            deploymentNode "Microsoft Azure — West Europe" "" "Azure" {
                deploymentNode "rg-hack-aks-we-01" "" "Resource Group" {
                    deploymentNode "AKS — aks-hack-we-01" "" "Kubernetes (plan Free, OIDC + Workload Identity)" {

                        deploymentNode "namespace: apisix" {
                            apisixInst = containerInstance shop.apisix
                        }
                        deploymentNode "namespace: prod" {
                            sfInst  = containerInstance shop.storefront
                            boInst  = containerInstance shop.backoffice
                            apiInst = containerInstance shop.api
                            roInst  = containerInstance shop.rollouts
                        }
                        deploymentNode "namespace: argocd" {
                            argoInst = containerInstance shop.argocd
                        }
                        deploymentNode "namespaces plateforme" {
                            cmInst  = containerInstance shop.certmgr
                            esoInst = containerInstance shop.eso
                        }
                    }
                    kvNode = infrastructureNode "Azure Key Vault" "Secrets app + GHCR (RBAC, Workload Identity)." "Azure"
                }
                deploymentNode "rg-hack-aks-nodes-we-01" "" "Resource Group (géré par AKS)" {
                    deploymentNode "VMSS — pool system" "Standard_D2s_v4 · autoscale 2→3 · Ubuntu" "" {
                    }
                    lbNode  = infrastructureNode "Standard Load Balancer" "" "Azure"
                    pipNode = infrastructureNode "IP publique statique" "pip-hack-apisix-we-01 · 20.160.228.31" "Azure"
                }
            }
            cfNode = infrastructureNode "Cloudflare DNS" "A michelin.shost.fr + *.michelin.shost.fr (DNS-only)." "External"

            cfNode -> pipNode "Résout vers"
            pipNode -> lbNode "Front-end LB"
            lbNode -> apisixInst "Trafic 443"
            esoInst -> kvNode "Workload Identity"
        }
    }

    views {
        systemContext shop "Contexte" "Niveau 1 — Contexte système." {
            include *
            autolayout lr
        }

        container shop "Conteneurs" "Niveau 2 — Conteneurs." {
            include *
            autolayout tb
        }

        component shop.argocd "Composants-ArgoCD" "Niveau 3 — Composants du moteur GitOps." {
            include *
            autolayout tb
        }

        deployment shop "Production" "Déploiement" "Projection sur Azure / AKS." {
            include *
            autolayout lr
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Database" {
                shape cylinder
            }
            element "Azure" {
                background #0078d4
                color #ffffff
            }
            element "Infrastructure Node" {
                background #0b8043
                color #ffffff
            }
        }
    }
}
