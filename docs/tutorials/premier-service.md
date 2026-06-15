# Déployer votre premier service

À la fin de ce tutoriel, votre service tourne en production et répond sur une URL HTTPS.
On prend l'exemple d'un service nommé `storefront`.

## Prérequis

- Un repo sous l'org `Hackaton-ESGI-x-Michelin` (ex. `storefront`).
- Un `Dockerfile` qui produit une image écoutant sur un port HTTP.

## 1. Conteneurisez votre service

Ajoutez un `Dockerfile` à la racine de votre repo. Exemple minimal (frontend statique) :

```dockerfile
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/
EXPOSE 80
```

## 2. Branchez la CI

Créez `.github/workflows/ci.yml` dans **votre** repo. Il appelle les workflows
réutilisables de la plateforme (build, test, scan, signature, push GHCR) :

```yaml
name: ci
on: [push, pull_request]
jobs:
  build:
    uses: Hackaton-ESGI-x-Michelin/hackation-ops/.github/workflows/reusable-build.yml@main
    with:
      image: ghcr.io/hackaton-esgi-x-michelin/storefront
      test_command: "npm ci && npm test"   # adaptez ou laissez vide
    secrets: inherit

  bump-prod:
    needs: build
    if: github.ref == 'refs/heads/main'
    uses: Hackaton-ESGI-x-Michelin/hackation-ops/.github/workflows/reusable-bump-prod.yml@main
    with:
      app: storefront
      image_tag: ${{ github.sha }}
    secrets:
      ops_write_token: ${{ secrets.OPS_WRITE_PAT }}
```

Rendez le package GHCR **public** (Settings du package) pour éviter les secrets de pull.

## 3. Déclarez le service à Argo CD

C'est l'étape « paramétrage Argo CD ». Ouvrez une **PR sur `hackation-ops`** qui :

1. crée `gitops/envs/prod/storefront/values.yaml` :

    ```yaml
    image:
      repository: ghcr.io/hackaton-esgi-x-michelin/storefront
      tag: latest          # la CSI/CD met à jour ce tag à chaque merge
    containerPort: 80
    ingress:
      host: michelin.shost.fr
    rollout:
      enabled: true        # canary via Argo Rollouts
    ```

2. ajoute votre service au générateur de l'ApplicationSet `gitops/appsets/ecommerce-prod.yaml` :

    ```yaml
    - name: storefront
    ```

Une fois la PR mergée, Argo CD crée automatiquement l'`Application` `prod-storefront`.

## 4. Vérifiez

- Dans **Argo CD** (<https://argocd.michelin.shost.fr>), l'application `prod-storefront`
  passe `Synced` puis `Healthy`.
- Votre service répond sur **<https://michelin.shost.fr>**.

!!! tip "Et les autres environnements ?"
    Chaque Pull Request labellisée `preview` crée un environnement éphémère
    `pr-<n>.michelin.shost.fr` — voir [Activer les previews de PR](../how-to/previews-pr.md).

## Et après ?

- [Mettre un service en prod](../how-to/deployer-en-prod.md) (détails des paramètres)
- [Gérer les secrets](../how-to/secrets.md)
- [Comprendre le flux GitOps](../explanation/gitops.md)
