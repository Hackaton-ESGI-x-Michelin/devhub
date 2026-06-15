# Architecture de la plateforme

La plateforme sépare deux responsabilités : **Terraform** provisionne le socle,
**Argo CD** livre les applications.

```
Terraform  ──▶  AKS + OIDC, Key Vault + Workload Identity, DNS Cloudflare,
                cert-manager, External Secrets, APISIX, Argo Rollouts, Argo CD,
                app-of-apps racine
Argo CD    ──▶  ApplicationSet prod (storefront / back-office / api)
                ApplicationSet previews (pr-<n>.michelin.shost.fr)
```

## Pourquoi cette frontière

Terraform détient les valeurs dynamiques d'identité (client-id de l'identité managée, URL
du Key Vault, IP publique…) : il installe donc tout le socle de façon déterministe. Une
fois Argo CD en place, **toute la livraison applicative passe par Git** — c'est la surface
que vous, développeurs, manipulez.

## Composants

| Composant | Rôle |
| --- | --- |
| **AKS** | Cluster Kubernetes (Azure) |
| **APISIX** | Gateway/ingress unique, terminaison TLS, routage par hôte |
| **cert-manager** | Certificats Let's Encrypt (DNS-01 Cloudflare) |
| **External Secrets** | Synchronise les secrets depuis Azure Key Vault |
| **Argo CD** | Réconciliation GitOps des applications |
| **Argo Rollouts** | Déploiement progressif (canary) en prod |

## Ce que vous touchez

En tant que dev, vous interagissez avec : **votre repo** (code + Dockerfile + CI) et le repo
**`hackation-ops`** (déclaration de votre service en GitOps). Vous ne touchez pas au socle
Terraform.

Voir aussi : [GitOps & flux de déploiement](gitops.md).
