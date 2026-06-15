# Activer les previews de PR

Chaque Pull Request peut obtenir un environnement éphémère
`pr-<numéro>.michelin.shost.fr`, créé et détruit automatiquement.

## Comment ça marche

Un `ApplicationSet` avec le **PR generator** d'Argo CD surveille les PR ouvertes de votre
repo. Pour chaque PR portant le label **`preview`**, il déploie une `Application` dédiée
dans le namespace `pr-<numéro>`, avec l'image taguée au **SHA de la PR**. À la fermeture de
la PR, le namespace est supprimé.

## Mettre en place pour un repo

Dupliquez `gitops/appsets/ecommerce-preview.yaml` dans `hackation-ops` en changeant le nom,
le repo et le préfixe d'hôte :

```yaml
metadata:
  name: preview-<service>
spec:
  generators:
    - pullRequest:
        github:
          owner: Hackaton-ESGI-x-Michelin
          repo: <service>
          tokenRef: { secretName: github-pr-token, key: token }
          labels: [preview]          # seules les PR labellisées déclenchent
        requeueAfterSeconds: 120
  template:
    spec:
      source:
        helm:
          parameters:
            - { name: image.repository, value: ghcr.io/hackaton-esgi-x-michelin/<service> }
            - { name: image.tag, value: "{{.head_sha}}" }
            - { name: ingress.host, value: "pr-{{.number}}.michelin.shost.fr" }
      destination:
        namespace: "pr-{{.number}}"
```

## Utiliser

1. Ouvrez une PR sur votre repo, ajoutez-lui le label **`preview`**.
2. La CI build et pousse l'image taguée au SHA.
3. Argo CD déploie `pr-<n>.michelin.shost.fr`.
4. Fermez la PR → l'environnement est nettoyé.

!!! note "Quota"
    Le label `preview` évite de créer un environnement pour **chaque** PR (la souscription
    a un quota serré). Ne labellisez que les PR à démontrer.
