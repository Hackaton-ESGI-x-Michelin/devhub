# Mettre un service en prod

Le déploiement prod est piloté par l'ApplicationSet `ecommerce-prod` dans `hackation-ops`.
Ajouter un service = deux fichiers dans une PR.

## 1. Fichier de valeurs

`gitops/envs/prod/<service>/values.yaml` — voir tous les paramètres dans
[Chart « app »](../reference/chart-app.md).

```yaml
image:
  repository: ghcr.io/hackaton-esgi-x-michelin/<service>
  tag: latest
replicaCount: 2
containerPort: 8080
ingress:
  host: <service>.michelin.shost.fr   # ou michelin.shost.fr pour le storefront
rollout:
  enabled: true
```

## 2. Entrée dans l'ApplicationSet

Dans `gitops/appsets/ecommerce-prod.yaml`, ajoutez votre service à la liste :

```yaml
generators:
  - list:
      elements:
        - name: storefront
        - name: <service>     # <-- ajout
```

## 3. Merge

Au merge sur `main`, Argo CD génère l'`Application` `prod-<service>` et la synchronise
(`prune` + `selfHeal` activés). Le tag d'image est ensuite **bumpé automatiquement** par la
CI de votre repo à chaque merge (workflow `reusable-bump-prod`).

!!! warning "Hostname"
    `<service>.michelin.shost.fr` est couvert par le certificat wildcard. N'utilisez que
    des hôtes sous `michelin.shost.fr` (voir [Hostnames & DNS](../reference/hostnames.md)).
