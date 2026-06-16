## Vue d'ensemble

L'**e-commerce Michelin Vélo** est une boutique en ligne premium dédiée à la gamme
vélo de Michelin. Le système se compose de blocs métier :

- un **front e-commerce** (catalogue, panier, tunnel d'achat) ;
- une **API** backend (catalogue, commandes, clients, paiement) ;
- une **gateway APISIX** comme porte d'entrée HTTPS unique ;
- une **base de données** (produits, commandes, clients) ;
- **Azure Key Vault** pour les secrets consommés par l'API.

Le paiement est délégué à un **prestataire externe**.

Ce workspace décrit le modèle C4 (Contexte, Conteneurs, Composants de l'API) et la
projection de déploiement sur Azure / AKS. L'outillage de plateforme et de
livraison (Argo CD, cert-manager, External Secrets, CI/CD) est volontairement
hors périmètre de ce modèle métier — il est documenté dans le DevHub
(« Schémas d'infrastructure »).
