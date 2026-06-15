# Se connecter à Argo CD

L'interface Argo CD est sur **<https://argocd.michelin.shost.fr>**.

## Connexion via GitHub (recommandé)

L'accès est restreint aux **membres de l'organisation GitHub `Hackaton-ESGI-x-Michelin`**
via OAuth (Dex). Concrètement :

1. Allez sur <https://argocd.michelin.shost.fr>.
2. Cliquez **« Log in via GitHub »**.
3. Autorisez l'application ; si vous êtes membre de l'org, vous êtes connecté.

On peut affiner par **équipe GitHub** (ex. `platform` = admin, autres = lecture/déploiement)
via la politique RBAC d'Argo CD.

!!! info "Pourquoi par l'org (et pas une whitelist d'emails)"
    Restreindre par appartenance à l'org (ou à une équipe) est plus robuste qu'une liste
    d'emails : l'accès suit automatiquement les arrivées/départs dans l'org GitHub. Dex
    supporte aussi le filtrage par `teams` si besoin d'un contrôle plus fin.

## Connexion admin (secours)

Le compte `admin` local reste disponible (dépannage / bootstrap) :

```bash
# mot de passe initial
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

Utilisateur `admin`, puis ce mot de passe. Changez-le et désactivez le compte local une fois
le SSO en place pour la prod.

## CLI

```bash
argocd login argocd.michelin.shost.fr --sso       # via GitHub
# ou
argocd login argocd.michelin.shost.fr --username admin
```
