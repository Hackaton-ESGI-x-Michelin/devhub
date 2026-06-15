# Gérer les secrets

Les secrets ne vivent **jamais** dans Git ni dans les images. Ils sont stockés dans
**Azure Key Vault** et injectés dans le cluster par **External Secrets Operator (ESO)**
via Workload Identity.

## 1. Stocker le secret dans Key Vault

```bash
az keyvault secret set \
  --vault-name kv-hack-abdozd2j \
  --name api-database-url \
  --value "postgres://..."
```

## 2. Déclarer l'`ExternalSecret` via le chart

Dans le `values.yaml` prod de votre service :

```yaml
externalSecret:
  enabled: true
  data:
    - secretKey: DATABASE_URL      # clé dans le Secret Kubernetes
      remoteKey: api-database-url  # nom du secret dans Key Vault
    - secretKey: JWT_SECRET
      remoteKey: api-jwt-secret
envFromSecret: prod-<service>      # monte le Secret en variables d'env
```

ESO crée alors un `Secret` Kubernetes `prod-<service>` synchronisé depuis Key Vault, monté
dans vos pods via `envFrom`.

## Comment ça marche

```
Pod ──(envFrom)── Secret K8s ──(ESO)── ClusterSecretStore "azure-kv" ──(Workload Identity)── Azure Key Vault
```

Le `ClusterSecretStore` est partagé (prod + tous les namespaces de preview), donc aucune
configuration d'identité n'est nécessaire côté service.

!!! warning "Accès au Key Vault"
    Pour écrire des secrets, votre identité Azure doit avoir le rôle
    **Key Vault Secrets Officer**. Demandez-le à l'équipe plateforme si `az keyvault secret set`
    échoue en `Forbidden`.
