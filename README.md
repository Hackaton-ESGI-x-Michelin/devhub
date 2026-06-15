# DevHub — Plateforme Michelin Vélo

Documentation d'onboarding développeur (Diátaxis), publiée via GitHub Pages avec MkDocs Material.

🔗 **Site** : https://hackaton-esgi-x-michelin.github.io/devhub/

## Développer la doc en local

```bash
pip install -r requirements.txt
mkdocs serve   # http://127.0.0.1:8000
```

## Structure ([Diátaxis](https://diataxis.fr/))

- `docs/tutorials/` — apprendre en faisant
- `docs/how-to/` — résoudre une tâche précise
- `docs/reference/` — information factuelle (valeurs, paramètres)
- `docs/explanation/` — comprendre l'architecture

Cette doc est **globale** (plateforme). Chaque équipe ajoute la doc de son service dans son propre repo.

Le déploiement est automatique à chaque push sur `main` (`.github/workflows/docs.yml`).
