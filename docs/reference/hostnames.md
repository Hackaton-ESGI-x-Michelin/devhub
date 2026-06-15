# Hostnames & DNS

Toute la plateforme est scopée sous le sous-domaine **`michelin.shost.fr`**. L'apex
`shost.fr` n'est jamais utilisé (il héberge d'autres services).

## Hôtes

| Service | Hôte |
| --- | --- |
| Storefront | `michelin.shost.fr` |
| Back-office | `admin.michelin.shost.fr` |
| API | `api.michelin.shost.fr` |
| Argo CD | `argocd.michelin.shost.fr` |
| Preview de PR | `pr-<n>.michelin.shost.fr` |

## TLS & routage

- DNS géré par Cloudflare, en **DNS-only** (pas de proxy) → pointent vers l'IP publique
  d'APISIX (`20.160.228.31`).
- **APISIX** termine le TLS avec un **certificat wildcard Let's Encrypt** unique couvrant
  `michelin.shost.fr` et `*.michelin.shost.fr` (émis par cert-manager, renouvelé
  automatiquement).
- Le routage par hôte est défini par l'`ApisixRoute` que le chart « app » génère pour vous.

!!! warning "Restez sous le wildcard"
    Tout hôte de la forme `<label>.michelin.shost.fr` est couvert par le certificat. Un
    hôte à deux niveaux (ex. `a.b.michelin.shost.fr`) ne le serait pas — évitez-les.
