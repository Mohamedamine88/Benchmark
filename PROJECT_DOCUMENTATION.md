# Documentation du projet: REST Benchmark

Ce document décrit le contexte, l’architecture, les données de test, la méthodologie et les résultats du benchmark mené sur plusieurs variantes d’implémentations REST. Il synthétise les éléments clés pour reproduire, analyser et interpréter les mesures.


1. Contexte du projet

- Nom du projet/benchmark
  - REST Benchmark: comparaison de frameworks et approches d’accès aux données pour des API CRUD et de lecture intensive.

- Technologies comparées
  - Variant A – Jersey (JAX-RS) classique: module `variant-a-jersey`
  - Variant C – Spring MVC: module `variant-c-springmvc`
  - Variant D – Spring Data (projections/repositories): module `variant-d-springdata`
  - Module commun d’entités et scripts: `common-entities`, `database`

- Objectif de l’étude
  - Évaluer la performance en lecture/écriture, la latence et la stabilité sous charge entre des approches REST différentes tout en conservant un modèle de données et des scénarios de test identiques. L’objectif est d’identifier les compromis latence/RPS/consommation et d’orienter les choix d’architecture.


2. Architecture et structure

- Organisation du dépôt
  - Racine
    - `docker-compose.yml`: orchestration des variantes et de la base si nécessaire
    - `docker-compose.monitoring.yml`: stack monitoring (Prometheus, Grafana, InfluxDB si applicable)
    - `SETUP_INSTRUCTIONS.md`, `GRAFANA_QUICK_START.md`, `EXECUTIVE_SUMMARY.md`, `BENCHMARK_RESULTS.md`
  - Backend
    - `common-entities`: entités Java communes, SQL de migration (`resources/db/migration/V1__Init_schema.sql`)
    - `variant-a-jersey`: API JAX-RS (Jersey). Bootstrapping via `JaxRsApplication`/`Main` et config Jackson
    - `variant-c-springmvc`: API Spring MVC (controllers explicites)
    - `variant-d-springdata`: API Spring Boot + Spring Data (projections, repositories)
  - Données et outils
    - `database`: Dockerfile et scripts `init-scripts/*.sql` pour initialiser/peupler la base
    - `jmeter`: scénarios `.jmx`, jeux de données CSV/JSON, script `run-all.ps1`
    - `monitoring`: Grafana (dashboards/provisioning) et Prometheus
    - `results`: résultats JMeter `.jtl` par variante/scénario

- Description des variantes/implémentations
  - Jersey (A): endpoints JAX-RS dans `resource/`, repositories simples. Config via `application-common.yml` et `persistence.xml`.
  - Spring MVC (C): controllers `controller/`, DTOs (`dto/ItemResponse.java`), repositories dédiés.
  - Spring Data (D): repositories et projections (`projection/`), auto-génération des requêtes, focus sur la réduction d’overhead de sérialisation et de mapping.

- Outils utilisés
  - Conteneurisation: Docker, docker-compose
  - Génération de charge: Apache JMeter (scénarios: `jmeter/scenarios/*.jmx`)
  - Données d’entrée: CSV/JSON dans `jmeter/data/`
  - Monitoring: Prometheus (`monitoring/prometheus/prometheus.yml`), Grafana (dashboard `monitoring/grafana/dashboards/jmeter-benchmark.json`)


3. Données de test

- Modèle de données
  - Entités principales: `Category`, `Item` (voir `common-entities/src/main/java/com/benchmark/entity/`)
  - Schéma: migration `V1__Init_schema.sql` et scripts d’init `database/init-scripts/*.sql`
  - Volumétrie: datasets fournis (CSV), payloads JSON de 1k à 5k champs/valeurs pour simuler des bodies lourds

- Scénarios de test
  - read-heavy.jmx: charges majoritairement lecture (GET) avec filtrages
  - heavy-body.jmx: requêtes avec payloads volumineux (POST/PUT), fichiers `payload-*.json`
  - join-filter.jmx: requêtes combinant jointures/filtrage serveur
  - mixed.jmx: mix CRUD avec ratios lecture/écriture
  - Jeux de données: `categories.csv`, `items.csv`, `category_items.csv`
  - Exécution: script `jmeter/run-all.ps1` pour lancer l’ensemble des scénarios sur chaque variante

- Configuration matérielle/logicielle
  - OS cible: Windows (PowerShell script fourni), conteneurs Docker Linux
  - Monitoring: Prometheus+Grafana via `docker-compose.monitoring.yml`
  - Paramètres JMeter: configurés dans les `.jmx`; RPS/threads/durée paramétrables via variables JMeter si nécessaire


4. Résultats des tests

- Métriques collectées
  - Débit: RPS (transactions/s)
  - Latences: moyenne, p95, p99
  - Taux d’erreur: % erreurs HTTP/transport
  - Utilisation ressources (si monitoring activé): CPU, mémoire, GC

- Emplacement des résultats
  - Fichiers `.jtl` par variante/scénario dans `results/` et à la racine:
    - `results/variant-a-*.jtl`, `results/variant-c-*.jtl`, `results/variant-d-*.jtl`
    - Exemple: `results/variant-d-read-heavy.jtl`
  - Résumé exécutif et synthèse: `EXECUTIVE_SUMMARY.md`, `BENCHMARK_RESULTS.md`

- Tableaux comparatifs (guide de lecture)
  - Importer les `.jtl` dans JMeter ou un tableur pour agréger: RPS moyen, p95, p99, erreurs
  - Comparer par scénario et variante. Exemple de structure de tableau:
    - Colonnes: Scénario | Variante | RPS | p95 (ms) | p99 (ms) | Erreurs (%)
    - Lignes: read-heavy | A/C/D; heavy-body | A/C/D; etc.

- Observations et incidents (attendus/à vérifier)
  - heavy-body: la sérialisation et le parsing JSON influencent fortement la latence; les pipelines Jackson/DTOs et la backpressure HTTP deviennent critiques
  - read-heavy: Spring Data avec projections peut réduire la latence et l’overhead mémoire, au prix d’une flexibilité moindre
  - join-filter: performances sensibles aux indexes DB et au mapping objet; vérifier plans d’exécution
  - Incidents typiques: saturation connexions DB, GC pauses, timeouts HTTP 5xx/429 sous forte charge


5. Éléments spécifiques

- Graphiques/dashboards
  - Grafana: dashboard `monitoring/grafana/dashboards/jmeter-benchmark.json`
  - Datasource/Provisioning: `monitoring/grafana/provisioning/*`, Prometheus config `monitoring/prometheus/prometheus.yml`
  - JMeter: possibilité d’exporter les graphs Summary Report/Response Times

- Recommandations et conclusions (génériques)
  - Pour workloads de lecture standard: la variante Spring Data (D) avec projections tend à offrir un bon ratio débit/latence, surtout sur read-heavy
  - Pour endpoints avec corps volumineux: optimiser la sérialisation (Jackson features, streaming), DTOs ciblés, compression HTTP
  - Indépendamment du framework: soigner le pool de connexions DB, la pagination, les indexes, et la gestion des timeouts
  - Automatiser l’exécution des scénarios via CI pour détecter les régressions

- Problèmes rencontrés et solutions (checklist)
  - Erreurs 5xx sous charge: ajuster pools (DB/HTTP threads), timeouts, et valider la contenance mémoire
  - P95/P99 élevées: profiler (JFR/async-profiler), activer métriques au niveau ORM, envisager projections et requêtes spécifiques
  - Variabilité des mesures: fixer l’affinité CPU des conteneurs, préchauffage (warmup) avant mesures, isoler la machine


6. Reproductibilité et exécution

- Préparation
  - Docker Desktop installé, JDK 17+, Maven
  - Initialiser la base via `database/` ou via docker-compose

- Lancement monitoring
  - `docker compose -f docker-compose.monitoring.yml up -d`
  - Ouvrir Grafana et importer le dashboard si non provisionné automatiquement

- Lancement des variantes et tests
  - Construire les images Maven/Docker des modules variants
  - Exécuter `jmeter/run-all.ps1` pour lancer les scénarios contre chaque service

- Analyse
  - Collecter les `.jtl` dans `results/`, générer les agrégats et comparer selon les tableaux prescrits ci-dessus


Annexes

- Fichiers clés
  - `jmeter/scenarios/*.jmx`, `jmeter/data/*`, `results/*.jtl`
  - `monitoring/grafana/**`, `monitoring/prometheus/prometheus.yml`
  - Code des variantes: `variant-a-jersey/**`, `variant-c-springmvc/**`, `variant-d-springdata/**`

- Liens internes
  - Guide d’installation: `SETUP_INSTRUCTIONS.md`
  - Résultats synthétiques: `BENCHMARK_RESULTS.md`, `EXECUTIVE_SUMMARY.md`
