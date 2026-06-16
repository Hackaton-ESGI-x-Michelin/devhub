# Structurizr — modèle C4 (source de vérité)

`workspace.dsl` décrit le modèle C4 de la plateforme Michelin Vélo en
[Structurizr DSL](https://docs.structurizr.com/dsl) : niveaux **Contexte**,
**Conteneurs**, **Composants** et un **Déploiement** (projection Azure / AKS).

Les diagrammes Mermaid de la documentation
(`docs/explanation/c4.md` et `docs/explanation/infrastructure.md`) en sont le
reflet rendu en ligne. Gardez les deux cohérents lors des mises à jour.

## Rendu local (vues interactives + export)

```bash
docker run -it --rm -p 8080:8080 \
  -v "$(pwd):/usr/local/structurizr" \
  structurizr/lite
# puis : http://localhost:8080
```

Structurizr Lite recharge le DSL à chaque rafraîchissement. Depuis l'UI on peut
exporter chaque vue en **PNG / SVG / PlantUML / Mermaid**.

## Export en ligne de commande (optionnel)

```bash
docker run --rm -v "$(pwd):/work" structurizr/cli \
  export -workspace /work/workspace.dsl -format mermaid -output /work/out
```

Formats utiles : `mermaid`, `plantuml`, `c4plantuml`.
