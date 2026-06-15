# DevHub — Projet Michelin Vélo

Documentation **générale** du projet : une boutique e-commerce pour donner de la visibilité
à la gamme **Michelin Vélo** auprès d'une clientèle premium (hackathon ESGI × Michelin).

Ce hub rassemble l'essentiel transverse : présentation du projet, architecture, et comment
livrer/déployer. **Chaque équipe complète la doc de son propre service dans son repo.**

<div class="grid cards" markdown>

-   :material-rocket-launch:{ .lg .middle } __Le projet__

    ---

    Vue d'ensemble du produit, des domaines et des repos.

    [:octicons-arrow-right-24: Vue d'ensemble](projet/vue-ensemble.md)

-   :material-school:{ .lg .middle } __Démarrer__

    ---

    Déployer votre premier service, de zéro à une URL en ligne.

    [:octicons-arrow-right-24: Tutoriel](tutorials/premier-service.md)

-   :material-wrench:{ .lg .middle } __Guides pratiques__

    ---

    Se connecter à Argo CD, mettre en prod, previews de PR, secrets.

    [:octicons-arrow-right-24: Guides](how-to/se-connecter-argocd.md)

-   :material-book-open-variant:{ .lg .middle } __Référence & archi__

    ---

    Paramètres du chart, workflows CI, architecture et GitOps.

    [:octicons-arrow-right-24: Référence](reference/chart-app.md)

</div>

## Repères

| Élément | Valeur |
| --- | --- |
| Org GitHub | `Hackaton-ESGI-x-Michelin` |
| Repo plateforme (source GitOps) | `hackation-ops` |
| Registry d'images | `ghcr.io/hackaton-esgi-x-michelin/<service>` |
| Domaine | `*.michelin.shost.fr` |
| Argo CD | <https://argocd.michelin.shost.fr> |

!!! note "Portée"
    Doc **transverse** au projet. La doc fonctionnelle/technique propre à un service
    (frontend, back-office, API) vit dans le repo de ce service.
