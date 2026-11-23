#!/usr/bin/env bash
# One-time model download. This is the ONLY step that needs internet.
# It runs a throwaway Ollama container on the default network, writes models
# into the shared volume, then exits. The real ollama service stays internal.
set -euo pipefail

MODELS=(
  "hermes3:8b"          # orchestrator / planner
  "qwen2.5-coder:7b"    # exploit + detection code
  "llama3.2:3b"         # cheap recon parsing / triage
  "nomic-embed-text"    # embeddings for RAG
)

VOLUME="purple-swarm_ollama-models"
docker volume create "$VOLUME" >/dev/null

docker run --rm -v "$VOLUME":/root/.ollama --entrypoint /bin/sh ollama/ollama:latest -c '
  ollama serve >/dev/null 2>&1 &
  sleep 5
  for m in '"${MODELS[*]}"'; do echo "pulling $m"; ollama pull "$m"; done
'

echo "Models stored in volume $VOLUME."
