# GitOps & flux de déploiement

Le principe GitOps : **l'état désiré du cluster est décrit dans Git**, et Argo CD réconcilie
le cluster vers cet état en continu. Vous ne faites jamais `kubectl apply` à la main — vous
faites une **Pull Request**.

## Flux prod

```
git push (votre repo, main)
   └─▶ CI: build + test + scan + push image GHCR (:sha)
        └─▶ CI: bump image.tag dans hackation-ops/gitops/envs/prod/<svc>/values.yaml (commit)
             └─▶ Argo CD détecte le commit, synchronise
                  └─▶ Argo Rollouts déroule le canary (25 % → 50 % → 100 %)
```

Le commit de bump est **traçable et auditable** : l'historique Git de `hackation-ops`
est l'historique des déploiements prod.

## Flux preview (PR éphémère)

```
PR ouverte + label "preview" (votre repo)
   └─▶ CI build l'image taguée au SHA de la PR
        └─▶ ApplicationSet (PR generator) crée une Application pr-<n>
             └─▶ déploiement dans le namespace pr-<n>, URL pr-<n>.michelin.shost.fr
PR fermée ─▶ Application + namespace supprimés
```

Les previews lisent le **SHA de la PR** directement (pas de commit de bump).

## Conséquences pratiques

- **Rollback** = `git revert` du commit de bump (Argo CD revient à la version précédente).
- **Pas de dérive** : `selfHeal` réaligne tout changement manuel sur l'état Git.
- **Source de vérité unique** : `hackation-ops`.

Voir aussi : [Mettre un service en prod](../how-to/deployer-en-prod.md).
