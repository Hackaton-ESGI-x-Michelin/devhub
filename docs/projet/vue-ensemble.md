# Vue d'ensemble du projet

## Le produit

Une boutique en ligne pour **Michelin Vélo** (Michelin LB 2 Wheels). Objectif métier :
populariser la gamme vélo auprès d'une clientèle premium, avec un parcours d'achat soigné
et une identité de marque forte.

## Les domaines

Le projet est découpé en services, chacun porté par une équipe et documenté dans son repo :

| Domaine | Rôle | Repo |
| --- | --- | --- |
| **Storefront** | Boutique client (frontend) | `storefront` |
| **Back-office** | Administration (frontend) | `back-office` |
| **API** | Backend / données / paiement | `api` |
| **Plateforme** | Infra, CI/CD, GitOps | `hackation-ops` |

> Les noms de repos ci-dessus sont indicatifs : ils suivent le service déclaré dans
> `gitops/envs/prod/<service>` et l'image `ghcr.io/hackaton-esgi-x-michelin/<service>`.

## Comment ça s'assemble

```
Navigateur ─▶ Cloudflare DNS ─▶ APISIX (TLS) ─▶ Service (frontend/API) sur AKS
                                                   └─ secrets via External Secrets / Key Vault
```

- Les **frontends** et l'**API** sont des conteneurs déployés sur Kubernetes (AKS).
- **APISIX** expose chaque service en HTTPS sous `*.michelin.shost.fr`.
- **Argo CD** déploie tout en continu depuis Git (GitOps).

Détails : [Architecture de la plateforme](../explanation/architecture.md) ·
[Flux GitOps](../explanation/gitops.md).

## Conventions transverses

- **Commits** : messages courts, une ligne.
- **Branches** : feature branch + PR ; `main` est déployable.
- **Images** : publiées sur GHCR, taguées au SHA.
- **Secrets** : jamais dans Git → Azure Key Vault (voir [Gérer les secrets](../how-to/secrets.md)).
