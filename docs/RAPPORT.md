# Rapport — Mettre en production une API de machine learning

**Groupe :** _à compléter_
**Dépôt :** <https://github.com/adel-855/cloud-sentiment-mini-project>
**Date :** _à compléter_

> Ce fichier est le plan du rapport à rendre en PDF. Remplacer les zones _en italique_,
> ajouter les captures aux emplacements indiqués. Les commandes sont dans le README.

## 1. Conteneurisation

| Choix | Raison |
|---|---|
| Build multi-stage (`python:3.12` → `python:3.12-slim`) | les compilateurs et caches pip ne sont pas dans l'image finale |
| Image **647 Mo** (< 800 Mo) | `scikit-learn` + `scipy` pèsent l'essentiel ; slim évite ~800 Mo de base |
| Utilisateur non-root `10001` | limite l'impact d'une évasion de conteneur |
| `HEALTHCHECK` sur `/health/live` | l'état du conteneur ne dépend pas de la base (sinon redémarrages en cascade) |
| `.dockerignore` | contexte de build réduit, pas de secrets ni de tests dans l'image |
| Compose : volume `pgdata` + `depends_on: service_healthy` | la base survit aux `down` et l'API attend qu'elle soit prête |

**Preuves :**

- [ ] `docker images` (taille) — capture
- [ ] `docker compose ps` (API et base *healthy*)
- [ ] `curl -X POST localhost:8000/predict …` → `positif`
- [ ] `docker compose exec api id` → `uid=10001`

**Problème rencontré / résolution :** _à compléter_

## 2. Intégration et livraison continues

| Choix | Raison |
|---|---|
| 3 jobs : `lint` → `test` → `docker` | on ne construit pas d'image si le code est faux |
| `needs: [lint, test]` | séquencement explicite, le pipeline échoue tôt |
| Tags `sha` (long) + `semver` + `latest` | traçabilité commit → image, versions stables pour les rollbacks |
| Cache BuildKit `type=gha` | builds suivants plus rapides |
| Trivy `severity=CRITICAL`, `exit-code=1`, `ignore-unfixed` | bloque les vulnérabilités corrigeables sans bloquer sur des CVE sans correctif |
| `pull_request` : build sans push | la PR est validée sans polluer le registry |
| Branche `main` protégée, merge par PR | aucun commit direct, pipeline au vert obligatoire |

**Preuves :**

- [ ] capture d'un run vert (3 jobs)
- [ ] capture des tags de l'image dans GHCR (`:sha`, `:latest`, `:v1.0.0`)
- [ ] capture d'une PR bloquée par un test rouge
- [ ] capture des règles de protection de branche

**Problème rencontré / résolution :** _à compléter_

## 3. Déploiement Kubernetes

| Choix | Raison |
|---|---|
| 2 replicas, `maxUnavailable: 0` | une suppression de pod ne coupe pas le service |
| Readiness `/health` (application + base) | un pod sans base ne reçoit pas de trafic |
| Liveness `/health/live` (application seule) | une panne PostgreSQL ne provoque pas de redémarrages en boucle |
| `startupProbe` 60 s | laisse le temps de charger le modèle scikit-learn |
| ConfigMap / Secret | configuration et identifiants hors de l'image |
| PVC 1 Gi pour PostgreSQL | les prédictions survivent au redémarrage des pods |
| requests/limits CPU-RAM | qualité de service et base du HPA |
| HPA 2→5 pods à 60 % CPU | absorbe les pics, revient à 2 au repos |
| PodDisruptionBudget `minAvailable: 1` | les opérations d'éviction gardent un pod disponible |
| `runAsNonRoot`, `readOnlyRootFilesystem`, `drop: ALL` | durcissement du conteneur |

**Preuves :**

- [ ] `kubectl -n sentiment get pods -o wide` (2 pods `Running`)
- [ ] `kubectl -n sentiment get svc,hpa,pvc`
- [ ] `curl localhost/predict` via le Service
- [ ] `kubectl delete pod` → réponse toujours 200 (boucle `while` ou capture avant/après)
- [ ] `kubectl -n sentiment get hpa` pendant une montée en charge

**Problème rencontré / résolution :** _à compléter_

## 4. Observabilité et KPI

| Niveau | KPI | Requête |
|---|---|---|
| Technique | latence p95 | `histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{route="/predict"}[5m])))` |
| Technique | taux d'erreur | `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))` |
| Technique | CPU / RAM par pod | `container_cpu_usage_seconds_total`, `container_memory_working_set_bytes` |
| ML | confiance moyenne | `sum(rate(prediction_confidence_sum[5m])) / sum(rate(prediction_confidence_count[5m]))` |
| ML | répartition par version | `sum by (model_version) (rate(predictions_total[5m]))` |
| Métier | volume de prédictions | `sum(rate(predictions_total[5m]))` |
| Métier | part d'avis positifs | `sum(rate(predictions_total{label="positif"}[5m])) / sum(rate(predictions_total[5m]))` |

**Alertes :** latence p95 > 500 ms pendant 5 min ; taux d'erreur 5xx > 5 % pendant 5 min ;
disponibilité < 99 % sur 1 h (`observability/alerts.yaml`).

**Preuves :**

- [ ] dashboard complet (3 niveaux de KPI)
- [ ] `FAULT_LATENCY_MS=800` → pic visible sur la latence p95
- [ ] `FAULT_ERROR_RATE=0.3` → taux d'erreur visible
- [ ] alerte en état *Firing* (capture Grafana + notification)
- [ ] capture de la charge (`kubectl run`/`hey`) et du HPA

**Problème rencontré / résolution :** _à compléter_

## 5. Note d'architecture

Voir [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) (schéma, cible GKE Autopilot, coût ~82 $/mois,
limites et améliorations).

## 6. Problèmes rencontrés (journal)

| Problème | Cause | Résolution |
|---|---|---|
| _à compléter_ | | |

## 7. Répartition du travail

| Membre | Étapes |
|---|---|
| _à compléter_ | |
