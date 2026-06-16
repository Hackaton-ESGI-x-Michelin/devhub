workspace "Michelin Vélo" "Modèle C4 métier de l'e-commerce Michelin Vélo (hackathon ESGI × Michelin)." {

    model {
        // --- Personnes ---
        client = person "Client" "Parcourt le catalogue et achète des produits Michelin Vélo."

        // --- Systèmes externes ---
        payment = softwareSystem "Prestataire de paiement" "Encaissement sécurisé des commandes." "External"

        // --- Système principal (blocs métier uniquement) ---
        shop = softwareSystem "E-commerce Michelin Vélo" "Boutique en ligne premium : front e-commerce + API." {

            apisix = container "APISIX" "Porte d'entrée unique : HTTPS, routage par hôte." "Apache APISIX"
            front  = container "Front e-commerce" "Catalogue, panier, tunnel d'achat." "Next.js (standalone, :3000)"

            api = container "API" "Catalogue, commandes, clients, paiement." "Backend (:8080)" {
                auth    = component "Authentification" "Sessions / JWT."
                catalog = component "Catalogue" "Produits, stocks."
                cart    = component "Panier" "Lignes, total."
                orders  = component "Commandes" "Création, suivi."
                pay     = component "Paiement" "Orchestration de l'encaissement."
            }

            database = container "Base de données" "Produits, commandes, clients." "SGBD" "Database"
            keyvault = container "Azure Key Vault" "Secrets consommés par l'API (DATABASE_URL, JWT_SECRET…)." "Azure (PaaS)" "Database"
        }

        // --- Niveau 1 : contexte ---
        client -> shop "Parcourt et achète" "HTTPS"
        shop -> payment "Initie les paiements" "HTTPS/API"

        // --- Niveau 2 : conteneurs ---
        client -> apisix "Navigue / achète" "HTTPS 443"
        apisix -> front "michelin.shost.fr" "HTTP"
        apisix -> api "api.michelin.shost.fr" "HTTP"
        front -> api "Appels API REST" "HTTPS"
        api -> database "Lit / écrit"
        api -> keyvault "Récupère ses secrets" "Workload Identity"
        api -> payment "Paiement" "HTTPS/API"

        // --- Niveau 3 : composants de l'API ---
        front -> auth "Authentifie"
        front -> catalog "Consulte le catalogue"
        front -> cart "Gère le panier"
        cart -> orders "Valide le panier"
        orders -> pay "Déclenche le paiement"
        auth -> keyvault "Clé de signature JWT"
        catalog -> database "Lit"
        orders -> database "Lit / écrit"
        pay -> payment "Encaisse"

        // --- Déploiement (projection des conteneurs métier sur Azure / AKS) ---
        deploymentEnvironment "Production" {
            deploymentNode "Microsoft Azure — West Europe" "" "Azure" {
                deploymentNode "rg-hack-aks-we-01" "" "Resource Group" {
                    deploymentNode "AKS — aks-hack-we-01" "" "Kubernetes (plan Free)" {
                        deploymentNode "namespace: apisix" {
                            apisixInst = containerInstance apisix
                        }
                        deploymentNode "namespace: prod" {
                            frontInst = containerInstance front
                            apiInst   = containerInstance api
                        }
                    }
                    deploymentNode "Azure Key Vault" "" "PaaS" {
                        kvInst = containerInstance keyvault
                    }
                    deploymentNode "Base de données" "" "PaaS / managée" {
                        dbInst = containerInstance database
                    }
                }
                deploymentNode "rg-hack-aks-nodes-we-01" "" "Resource Group (géré par AKS)" {
                    deploymentNode "VMSS — pool system" "Standard_D2s_v4 · autoscale 2→3 · Ubuntu" "" {
                    }
                    lbNode  = infrastructureNode "Standard Load Balancer" "" "Azure"
                    pipNode = infrastructureNode "IP publique statique" "pip-hack-apisix-we-01 · 20.160.228.31" "Azure"
                }
            }
            deploymentNode "Cloudflare" "" "DNS (DNS-only)" "External" {
                cfNode = infrastructureNode "Cloudflare DNS" "A michelin.shost.fr + *.michelin.shost.fr." "External"
            }

            cfNode -> pipNode "Résout vers"
            pipNode -> lbNode "Front-end LB"
            lbNode -> apisixInst "Trafic 443"
        }
    }

    views {
        systemContext shop "Contexte" "Niveau 1 — Contexte système." {
            include *
            autolayout lr
        }

        container shop "Conteneurs" "Niveau 2 — Conteneurs métier." {
            include *
            autolayout tb
        }

        component api "Composants-API" "Niveau 3 — Composants de l'API." {
            include *
            autolayout tb
        }

        deployment shop "Production" "Deploiement" "Projection des conteneurs métier sur Azure / AKS." {
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
