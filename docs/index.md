# DevHub — Plateforme Michelin Vélo

Bienvenue. Cette plateforme déploie l'e-commerce Michelin Vélo sur **Azure AKS**, avec
livraison continue en **GitOps via Argo CD**, exposition par **APISIX** et secrets via
**External Secrets + Azure Key Vault**.

Vous êtes développeur d'un service (frontend ou backend) ? Vous êtes au bon endroit pour
savoir **comment brancher votre service sur la plateforme**.

## En une phrase

> Vous livrez une **image Docker sur GHCR** ; vous déclarez votre service dans le repo
> **`hackation-ops`** ; **Argo CD** le déploie et **APISIX** l'expose en HTTPS.

## Par où commencer ?

<div class="grid cards" markdown>

- :material-school: **[Tutoriel : déployer votre premier service](tutorials/premier-service.md)**
  Le parcours complet, de zéro à une URL en ligne.

- :material-wrench: **[Guides pratiques](how-to/deployer-en-prod.md)**
  Mettre en prod, activer les previews de PR, gérer les secrets.

- :material-book-open-variant: **[Référence](reference/chart-app.md)**
  Paramètres du chart, workflows CI, hostnames.

- :material-lightbulb: **[Explications](explanation/architecture.md)**
  Architecture et flux GitOps de la plateforme.

</div>

## Repères

| Élément | Valeur |
| --- | --- |
| Org GitHub | `Hackaton-ESGI-x-Michelin` |
| Repo plateforme (source GitOps) | `hackation-ops` |
| Registry d'images | `ghcr.io/hackaton-esgi-x-michelin/<service>` |
| Domaine | `*.michelin.shost.fr` |
| Argo CD | <https://argocd.michelin.shost.fr> |

!!! note "Doc globale"
    Cette documentation décrit la **plateforme**. La doc propre à chaque service vit
    dans le repo de ce service.
