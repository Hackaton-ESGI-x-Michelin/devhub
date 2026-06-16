# 1. Périmètre du modèle C4 limité au métier

Date: 2026-06-16

## Status

Accepted

## Context

Le DevHub doit fournir des schémas clairs et professionnels. Un premier jet du
modèle C4 mélangeait les blocs métier (e-commerce, API) et l'outillage de
plateforme/livraison (Argo CD, Argo Rollouts, cert-manager, External Secrets,
CI/CD). Ce mélange rendait le C4 difficile à lire et noyait le métier sous des
préoccupations d'exploitation.

## Decision

Le modèle C4 (vues Contexte, Conteneurs, Composants) ne contient que les **blocs
métier utiles** : front e-commerce, API et ses composants, gateway APISIX, base
de données, Key Vault et le prestataire de paiement externe.

L'infrastructure complète (plateforme Kubernetes, GitOps, CI/CD, réseau Azure)
est décrite séparément dans la page « Schémas d'infrastructure » du DevHub, et la
vue *Deployment* de ce workspace projette les conteneurs métier sur Azure / AKS.

## Consequences

- Le C4 reste lisible et centré sur le produit.
- La frontière métier / plateforme est explicite et documentée.
- Toute évolution du découpage des applications doit être répercutée à la fois
  dans ce workspace et dans la documentation d'infrastructure.
