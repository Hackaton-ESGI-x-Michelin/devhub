# Schémas d'infrastructure

Projection concrète de l'[architecture C4](c4.md) sur **Azure** et sur le **cluster
Kubernetes**. Le socle est provisionné par Terraform ; les applications sont livrées
par Argo CD ([frontière](architecture.md)).

!!! note "Contraintes de dimensionnement"
    Souscription Azure étudiante, **quota régional de 10 vCPU** (West Europe).
    Pool de nœuds `Standard_D2s_v4` (2 vCPU), autoscale **2 → 3**, `max_surge = 1`,
    et un **unique** LoadBalancer APISIX. Tout est dimensionné pour rester dans ce quota.

---

## 1. Ressources Azure

Groupes de ressources, cluster, identités et réseau public.

```mermaid
flowchart TB
  subgraph sub["Souscription Azure étudiante · West Europe"]
    subgraph rgState["RG · rg-hack-tfstate-we-01"]
      sa[("Storage Account<br/>sthacktfstate…<br/><i>état Terraform (blob)</i>")]:::azstore
    end

    subgraph rgAks["RG · rg-hack-aks-we-01"]
      aks["AKS · aks-hack-we-01<br/><i>plan Free · K8s managé</i><br/>OIDC + Workload Identity · RBAC"]:::azsvc
      kv[("Key Vault · kv-hack-…<br/><i>RBAC · secrets app + GHCR</i>")]:::azstore
      idEso["Managed Identity · id-eso-…<br/><i>federated cred → ESO SA</i>"]:::azid
    end

    subgraph rgNodes["RG des nœuds · rg-hack-aks-nodes-we-01"]
      vmss["VMSS · pool « system »<br/><i>Standard_D2s_v4 · 2→3 nœuds</i><br/>Ubuntu · max_pods 60"]:::aznode
      lb["Standard Load Balancer"]:::aznet
      pip["IP publique statique<br/>pip-hack-apisix-we-01<br/><b>20.160.228.31</b>"]:::aznet
    end
  end

  cloudflare["Cloudflare DNS · zone shost.fr<br/><i>A michelin.shost.fr + *.michelin.shost.fr (DNS-only)</i>"]:::ext

  aks --> vmss
  vmss --> lb --> pip
  cloudflare -.->|"résout vers"| pip
  aks -. "héberge le pool dans" .-> rgNodes
  idEso -->|"Key Vault Secrets User"| kv
  aks -. "OIDC issuer" .-> idEso

  classDef azsvc fill:#0078d4,stroke:#004578,color:#fff;
  classDef aznode fill:#50a0e0,stroke:#004578,color:#fff;
  classDef azstore fill:#7a5cc6,stroke:#4b2e83,color:#fff;
  classDef aznet fill:#0b8043,stroke:#054d28,color:#fff;
  classDef azid fill:#c0392b,stroke:#7b241c,color:#fff;
  classDef ext fill:#f38020,stroke:#a8550f,color:#fff;
```

| Groupe de ressources | Contenu |
| --- | --- |
| `rg-hack-tfstate-we-01` | Storage Account = backend d'état Terraform (bootstrap, une fois). |
| `rg-hack-aks-we-01` | Cluster AKS, Key Vault, identité managée ESO. |
| `rg-hack-aks-nodes-we-01` | Ressources gérées par AKS : VMSS (nœuds), Load Balancer, **IP publique statique** d'APISIX. |

L'IP publique est créée **par nom** dans le RG des nœuds pour qu'APISIX (déployé
plus tard) l'attache via les annotations de son `Service`, et que le DNS pointe
dessus de façon stable.

---

## 2. Réseau du cluster

Plugin réseau et plages d'adressage (Azure CNI **overlay**, dataplane **Cilium**).

```mermaid
flowchart LR
  subgraph net["Profil réseau AKS"]
    direction TB
    plugin["network_plugin: azure (overlay)<br/>data_plane + policy: cilium<br/>load_balancer_sku: standard"]:::info
    pods["Pod CIDR<br/>10.244.0.0/16"]:::cidr
    svc["Service CIDR<br/>10.0.0.0/16"]:::cidr
    dns["DNS du cluster<br/>10.0.0.10"]:::cidr
  end
  classDef info fill:#eef2ff,stroke:#3949ab,color:#1a237e;
  classDef cidr fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20;
```

- **Overlay** : les pods ont des IP hors du VNet (pas de consommation d'IP du subnet) → adapté au petit quota.
- **Cilium** assure à la fois le data plane et les *NetworkPolicies*.

---

## 3. Topologie Kubernetes

Vue interne du cluster : namespaces, charges applicatives et ressources de plateforme.

```mermaid
flowchart TB
  internet(["🌐 Internet"]):::net

  subgraph cluster["Cluster AKS · aks-hack-we-01"]
    subgraph nsApisix["namespace: apisix"]
      apisixSvc["Service LoadBalancer<br/><i>annoté → IP publique statique</i>"]:::svc
      apisixPod["APISIX gateway + ingress-controller"]:::pod
      etcd["etcd (1 réplica)<br/><i>bitnamilegacy/etcd</i>"]:::pod
      apisixTls["ApisixTls « michelin »<br/><i>SNI wildcard, cross-namespace</i>"]:::crd
    end

    subgraph nsProd["namespace: prod"]
      sfRollout["Rollout storefront<br/><i>2 réplicas · canari</i>"]:::pod
      boRollout["Rollout back-office<br/><i>1 réplica · canari</i>"]:::pod
      apiRollout["Rollout api<br/><i>2 réplicas · canari</i>"]:::pod
      prodRoutes["ApisixRoute ×3<br/><i>par hôte</i>"]:::crd
      prodSecret["Secret prod-api<br/><i>via ExternalSecret</i>"]:::secret
    end

    subgraph nsPrev["namespace: pr-&lt;n&gt; / pr-&lt;n&gt;-api (éphémère)"]
      prevDeploy["Deployment<br/><i>1 réplica (pas de canari)</i>"]:::pod
      prevRoute["ApisixRoute<br/>pr-&lt;n&gt;.michelin.shost.fr"]:::crd
    end

    subgraph nsArgo["namespace: argocd"]
      argoCtrl["application-controller"]:::pod
      argoServer["argocd-server (insecure, TLS @ APISIX)"]:::pod
      argoRepo["repo-server"]:::pod
      appset["applicationset-controller"]:::pod
      dex["dex (SSO GitHub org)"]:::pod
    end

    subgraph nsPlat["namespaces plateforme"]
      cm["cert-manager<br/><i>+ ClusterIssuer Let's Encrypt</i>"]:::pod
      esoPod["external-secrets<br/><i>+ ClusterSecretStore azure-kv</i>"]:::pod
      rolloutsCtrl["argo-rollouts controller"]:::pod
    end
  end

  kv[("Azure Key Vault")]:::ext
  ghcr["GHCR (privé)"]:::ext
  le["Let's Encrypt"]:::ext
  gitops["Git · hackation-ops"]:::ext

  internet -->|HTTPS 443| apisixSvc --> apisixPod
  apisixPod --> sfRollout
  apisixPod --> boRollout
  apisixPod --> apiRollout
  apisixPod --> prevDeploy
  apisixPod --> argoServer
  apisixPod -. "lit le certificat" .-> apisixTls

  cm -->|DNS-01| le
  cm -. "Secret michelin-tls" .-> apisixTls
  esoPod <-->|Workload Identity| kv
  esoPod -. "matérialise" .-> prodSecret
  argoCtrl -->|sync / selfHeal| nsProd
  argoCtrl -->|sync / selfHeal| nsPrev
  appset -. "génère Applications" .-> argoCtrl
  argoRepo <-->|clone| gitops
  sfRollout -. pull .-> ghcr
  apiRollout -. pull .-> ghcr
  rolloutsCtrl -. "pilote" .-> apiRollout

  classDef net fill:#263238,stroke:#000,color:#fff;
  classDef svc fill:#0b8043,stroke:#054d28,color:#fff;
  classDef pod fill:#326ce5,stroke:#1a3a8f,color:#fff;
  classDef crd fill:#9c27b0,stroke:#5e1370,color:#fff;
  classDef secret fill:#c0392b,stroke:#7b241c,color:#fff;
  classDef ext fill:#999999,stroke:#6b6b6b,color:#fff;
```

??? abstract "Vue de déploiement Structurizr (conteneurs métier sur Azure / AKS, SVG exporté du DSL)"
    ![Vue de déploiement — rendu Structurizr](../assets/structurizr/deploiement.svg){ loading=lazy }

!!! tip "Une seule porte d'entrée, un seul certificat"
    Tout le trafic entre par le `Service` LoadBalancer **unique** d'APISIX (IP
    publique statique). La ressource `ApisixTls` sert le certificat wildcard
    `michelin-tls` pour **tous** les hôtes, quel que soit le namespace du backend
    (prod comme `pr-<n>`). Voir [Hostnames & DNS](../reference/hostnames.md).

---

## 4. Cheminement d'une requête (TLS de bout en bout)

```mermaid
sequenceDiagram
  autonumber
  actor U as Navigateur
  participant CF as Cloudflare DNS
  participant LB as Azure LB (IP statique)
  participant GW as APISIX (gateway + TLS)
  participant SVC as Service K8s
  participant POD as Pod (storefront / api)

  U->>CF: Résout michelin.shost.fr
  CF-->>U: 20.160.228.31 (DNS-only)
  U->>LB: HTTPS 443
  LB->>GW: Transfert L4
  Note over GW: Termine le TLS (cert wildcard michelin-tls)<br/>Sélection de route par hôte (ApisixRoute)
  GW->>SVC: HTTP vers le backend du bon namespace
  SVC->>POD: Équilibrage vers un réplica sain
  POD-->>U: Réponse HTTPS
```

---

## 5. Pipeline CI/CD → cluster

De `git push` jusqu'au canari en production. Détail du raisonnement :
[GitOps & flux de déploiement](gitops.md).

```mermaid
flowchart LR
  push(["git push / PR<br/>(repo app)"]):::trigger

  subgraph gha["GitHub Actions — reusable-node-ci"]
    q["quality<br/>lint·types·tests·audit"]:::job
    s["security<br/>Trivy fs"]:::job
    b["build<br/>buildx · SBOM · provenance<br/>Trivy image · cosign"]:::job
    r["release<br/>semantic-release"]:::job
  end

  ghcr["GHCR (privé)<br/>:sha → :version"]:::ext
  bumpPR["PR auto bump<br/>gitops/envs/prod/&lt;app&gt;"]:::trigger

  subgraph k8s["Cluster AKS"]
    argo["Argo CD<br/>sync"]:::svc
    canary["Argo Rollouts<br/>25% → 50% → 100%"]:::svc
    prod["Pods prod"]:::pod
  end

  push --> q --> s --> b --> r
  b -->|"image signée :sha"| ghcr
  r -->|version SemVer| bumpPR
  r -->|"retag :version"| ghcr
  bumpPR -->|merge auto sur main| argo
  argo --> canary --> prod
  prod -. "pull image signée" .-> ghcr

  classDef trigger fill:#fbc02d,stroke:#b58a00,color:#000;
  classDef job fill:#85bbf0,stroke:#5d82a8,color:#000;
  classDef svc fill:#0b8043,stroke:#054d28,color:#fff;
  classDef pod fill:#326ce5,stroke:#1a3a8f,color:#fff;
  classDef ext fill:#999999,stroke:#6b6b6b,color:#fff;
```

Les **previews de PR** ne passent pas par le *bump* : l'`ApplicationSet` à
générateur Pull Request lit directement le SHA de la PR et déploie un
`Deployment` simple (sans canari) dans un namespace `pr-<n>` éphémère, supprimé à
la fermeture de la PR.
