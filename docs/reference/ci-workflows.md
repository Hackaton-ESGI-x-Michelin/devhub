# Workflows CI réutilisables

Hébergés dans `hackation-ops/.github/workflows/`, appelés via `workflow_call` depuis les
repos de service.

## `reusable-build.yml`

Build → test → image Docker → scan Trivy → SBOM → signature cosign (keyless) → push GHCR.

| Entrée | Requis | Défaut | Description |
| --- | --- | --- | --- |
| `image` | oui | — | Image GHCR sans tag (`ghcr.io/hackaton-esgi-x-michelin/<svc>`) |
| `context` | non | `.` | Contexte de build Docker |
| `dockerfile` | non | `Dockerfile` | Chemin du Dockerfile |
| `test_command` | non | `""` | Commande de test exécutée avant le build |

Tags poussés : `:<sha>` et `:<branche>`. Échoue si Trivy trouve une vuln `CRITICAL`/`HIGH`
corrigeable.

```yaml
uses: Hackaton-ESGI-x-Michelin/hackation-ops/.github/workflows/reusable-build.yml@main
with:
  image: ghcr.io/hackaton-esgi-x-michelin/api
  test_command: "go test ./..."
secrets: inherit
```

## `reusable-bump-prod.yml`

Met à jour `image.tag` dans `gitops/envs/prod/<app>/values.yaml` et commit dans
`hackation-ops` → Argo CD synchronise la prod.

| Entrée | Requis | Description |
| --- | --- | --- |
| `app` | oui | Nom du service (= dossier sous `gitops/envs/prod/`) |
| `image_tag` | oui | Tag à déployer (généralement `${{ github.sha }}`) |

| Secret | Description |
| --- | --- |
| `ops_write_token` | PAT avec accès écriture sur `hackation-ops` (`OPS_WRITE_PAT`) |

À n'appeler que sur `main` :

```yaml
bump-prod:
  needs: build
  if: github.ref == 'refs/heads/main'
  uses: Hackaton-ESGI-x-Michelin/hackation-ops/.github/workflows/reusable-bump-prod.yml@main
  with: { app: api, image_tag: "${{ github.sha }}" }
  secrets: { ops_write_token: "${{ secrets.OPS_WRITE_PAT }}" }
```

!!! note "Previews"
    Les previews de PR n'utilisent **pas** `bump-prod` : l'ApplicationSet lit directement le
    SHA de la PR. Seule la prod est bumpée par commit GitOps.
