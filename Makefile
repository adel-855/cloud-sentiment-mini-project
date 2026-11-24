# Raccourcis : tout relancer depuis zéro.
SHELL := /bin/bash
IMAGE ?= ghcr.io/adel-855/cloud-sentiment-mini-project:latest

.PHONY: help venv lint test compose-up compose-down build k8s-env k8s-up k8s-down k8s-status
.PHONY: fault-latency fault-errors fault-off logs

help: ## Liste les commandes
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-16s %s\n", $$1, $$2}'

venv: ## Crée le venv et installe les dépendances de dev
	python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt

lint: ## ruff check + format
	.venv/bin/ruff check . && .venv/bin/ruff format --check .

test: ## pytest
	.venv/bin/pytest -q

compose-up: ## Stack locale (API + PostgreSQL)
	docker compose up --build -d

compose-down: ## Arrête la stack locale
	docker compose down

build: ## Construit l'image et affiche sa taille
	docker build -t sentiment-api:local . && docker images sentiment-api:local --format '{{.Repository}}:{{.Tag}} {{.Size}}'

k8s-env: ## Crée k8s/.env depuis l'exemple (à éditer)
	test -f k8s/.env || cp k8s/.env.example k8s/.env

k8s-up: k8s-env ## Applique les manifests (kustomize)
	kubectl apply -k k8s/

k8s-down: ## Supprime tout le namespace
	kubectl delete namespace sentiment --ignore-not-found

k8s-status: ## État des ressources
	kubectl -n sentiment get deploy,pods,svc,hpa,pvc

fault-latency: ## Simule 800 ms de latence
	kubectl -n sentiment set env deploy/api FAULT_LATENCY_MS=800

fault-errors: ## Simule 30 % d'erreurs
	kubectl -n sentiment set env deploy/api FAULT_ERROR_RATE=0.3

fault-off: ## Désactive les pannes simulées
	kubectl -n sentiment set env deploy/api FAULT_LATENCY_MS=0 FAULT_ERROR_RATE=0

logs: ## Logs de l'API
	kubectl -n sentiment logs -l app.kubernetes.io/name=api --tail=100 -f
