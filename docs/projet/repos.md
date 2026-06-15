# Organisation des repos

Tous les repos vivent sous l'org GitHub **`Hackaton-ESGI-x-Michelin`**.

## Repos de service (polyrepo)

Un repo par service. Chacun contient son code, son `Dockerfile`, sa CI (qui appelle les
workflows de la plateforme) et **sa propre documentation**.

```
storefront/     # frontend boutique
back-office/    # frontend admin
api/            # backend
└── .github/workflows/ci.yml   # appelle reusable-build + reusable-bump-prod
└── Dockerfile
└── README.md / docs propres au service
```

## Repo plateforme — `hackation-ops`

Source de vérité **GitOps** et **infrastructure** :

```
hackation-ops/
├── terraform/         # socle (AKS, Key Vault, DNS, plateforme)
├── gitops/
│   ├── charts/app/    # chart Helm partagé par tous les services
│   ├── envs/prod/     # valeurs prod par service (déclaration Argo CD)
│   └── appsets/       # ApplicationSets prod + previews
└── .github/workflows/ # reusable-build, reusable-bump-prod, terraform, ...
```

## Repo doc — `devhub`

Ce site. Documentation **transverse** au projet (MkDocs Material, déployé sur GitHub Pages).

## Où documenter quoi

| Sujet | Où |
| --- | --- |
| Fonctionnel/technique d'un service | repo du service |
| Déploiement, GitOps, infra, conventions transverses | `devhub` (ce site) |
| Manifests & valeurs de déploiement | `hackation-ops` |
