# Chart Helm « app »

Chart générique partagé (`gitops/charts/app` dans `hackation-ops`) utilisé par tous les
services. Vous le configurez via un `values.yaml` (prod) ou des paramètres (preview).

## Valeurs

| Clé | Défaut | Description |
| --- | --- | --- |
| `image.repository` | `""` | Image GHCR (sans tag) |
| `image.tag` | `latest` | Tag d'image (bumpé par la CI en prod) |
| `replicaCount` | `2` | Nombre de réplicas |
| `containerPort` | `80` | Port HTTP du conteneur |
| `service.port` | `80` | Port du Service |
| `ingress.host` | `""` | Hôte public (sous `michelin.shost.fr`) **requis** |
| `ingress.path` | `/*` | Chemin routé par APISIX |
| `rollout.enabled` | `false` | `true` = Argo Rollouts (canary) ; `false` = Deployment simple |
| `rollout.steps` | 25→50→100 % | Étapes du canary |
| `resources` | requests 25m/64Mi | Ressources (gardez-les basses, quota serré) |
| `externalSecret.enabled` | `false` | Active la synchro Key Vault |
| `externalSecret.data` | `[]` | Liste `{secretKey, remoteKey}` |
| `envFromSecret` | `""` | Monte un Secret en variables d'env |
| `env` | `[]` | Variables d'env non secrètes `{name, value}` |
| `probes.enabled` | `true` | Liveness/readiness HTTP |
| `probes.path` | `/` | Chemin des probes |

## Ressources générées

- `Rollout` (si `rollout.enabled`) ou `Deployment`
- `Service` (ClusterIP)
- `ApisixRoute` (routage par hôte, TLS géré globalement par la plateforme)
- `ExternalSecret` (si `externalSecret.enabled`)

## Exemple complet (backend)

```yaml
image:
  repository: ghcr.io/hackaton-esgi-x-michelin/api
  tag: latest
containerPort: 8080
ingress:
  host: api.michelin.shost.fr
rollout:
  enabled: true
externalSecret:
  enabled: true
  data:
    - { secretKey: DATABASE_URL, remoteKey: api-database-url }
envFromSecret: prod-api
probes:
  path: /health
```
