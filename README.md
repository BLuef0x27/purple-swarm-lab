# Purple Swarm Lab

**Two AI agent swarms, one red and one blue, fighting inside a fully local, air-gapped arena. Built for $0.**

The red swarm attacks intentionally vulnerable targets, and the arena sends telemetry into Splunk. The blue swarm triages, investigates, and proposes responses through a deny-by-default policy gate. Each round gets scored by MITRE ATT&CK coverage: which techniques red pulled off, and which ones blue caught.

> Lab only. All offensive activity targets containers on an internal Docker network on hardware I own. See [SECURITY.md](SECURITY.md).

---

## Why this exists

Companies are deploying autonomous agents faster than they can secure them. This project is a hands-on answer to two questions:

1. **How do you deploy agentic AI safely?** That means containment, least privilege, policy gates, and auditability.
2. **Can AI agents do useful security work on both sides?** That means offense, detection, response, and how to measure them.

## Design principles

- **Containment is the main engineering problem.** Every agent network is a Docker `internal` network with no route out of the host, and no container gets the Docker socket.
- **Agent output is a proposal, not an action.** Blue responses go through a policy gate, and red needs a human gate for anything destructive.
- **No knowledge leakage between teams.** Red and blue get separate vector stores, so the coverage score measures detection, not cheating.
- **$0 and in-house.** Local models via Ollama, Splunk Free, open-source everything. The internet is touched only once, to download images and models.

---

## Architecture

```
                 +-------------------- HOST (Ubuntu 24.04) --------------------+
                 |                                                             |
  llm-red  ----> |  ollama (local LLMs)  <---- llm-blue                         |
  (internal)     |  qdrant-red                qdrant-blue   (internal)         |
                 |      ^                          ^                           |
                 |      |                          |                           |
                 |   red-cai  ---- arena-net ---> juice-shop, dvwa             |
                 |   (CAI)         (internal)          |                       |
                 |                                     | logs (Docker driver)  |
                 |                                     v                       |
                 |   blue (defensa_azul) -- siem-net --> splunk (Free)          |
                 |                          (internal)    UI: 127.0.0.1:8000   |
                 +-------------------------------------------------------------+
```

| Network | Members | Internet |
|---|---|---|
| `llm-red` | red-cai, ollama, qdrant-red | No |
| `llm-blue` | blue, ollama, qdrant-blue | No |
| `arena-net` | red-cai, juice-shop, dvwa | No |
| `siem-net` | blue, splunk | No |
| `mgmt-net` | splunk (UI on localhost only) | Bridge, for the UI |

Red **cannot** reach Splunk, blue's knowledge store, or the internet. `scripts/verify-isolation.sh` proves it.

---

## Stack (all free)

| Layer | Tool | Cost |
|---|---|---|
| Red agents | [CAI (Cybersecurity AI)](https://github.com/aliasrobotics/cai) | Free, open source |
| Blue agents | [defensa_azul](https://github.com/rsfl/defensa_azul) | Free, open source |
| Models | [Ollama](https://ollama.com), local CPU inference | Free |
| SIEM | Splunk Enterprise, Free license (500 MB/day) | Free |
| Targets | OWASP Juice Shop, DVWA | Free |
| RAG | Qdrant + `nomic-embed-text` | Free |

### Models (sized for CPU inference)

| Role | Model | Why |
|---|---|---|
| Orchestrator / planner | `hermes3:8b` | Good tool calling |
| Exploit + detection code | `qwen2.5-coder:7b` | Strong coder for its size |
| Recon parsing / triage | `llama3.2:3b` | Fast and cheap |
| Embeddings | `nomic-embed-text` | Local RAG |

**Hardware:** Ryzen 7 5800X (8c/16t), 64 GB RAM, Ubuntu 24.04. Inference runs on the CPU, since the RX 550 isn't supported by ROCm. Expect 7 to 8B models to be usable but slow. That's fine for a lab, and the one-request-at-a-time limit keeps runaway loops cheap.

---

## Quick start

```bash
git clone https://github.com/<you>/purple-swarm-lab.git
cd purple-swarm-lab

# 1. Secrets
cp .env.example .env                    # fill with: openssl rand -hex 24
cp red/red.env.example red/red.env
chmod 600 .env red/red.env

# 2. One-time downloads (the only step that needs internet)
docker compose pull
docker compose --profile red build
./scripts/pull-models.sh

# 3. Arena + SIEM + models (no red yet)
docker compose up -d

# 4. Prove the walls hold
./scripts/verify-isolation.sh
```

Splunk UI: `http://127.0.0.1:8000` (user `admin`, password from `.env`). From another device, use an SSH tunnel.

## Build order

1. **Arena + Splunk.** Once Splunk is healthy, ship target logs to it:
   `docker compose -f docker-compose.yml -f docker-compose.logging.yml up -d juice-shop dvwa`,
   then search `sourcetype=docker:arena` in Splunk to confirm the logs arrive.
2. **Blue in observe mode.** Triage and reports must work on real telemetry. See [blue/README.md](blue/README.md).
3. **Red.** `docker compose --profile red up -d`, then rerun `verify-isolation.sh`.
4. **Close the purple loop.** Log each round in `scoring/coverage-template.csv`.
5. **Expand autonomy last,** only after containment is proven.

---

## Roadmap

- [ ] Arena up, logs in Splunk
- [ ] Blue triage + reporting in observe mode
- [ ] Red swarm contained and verified
- [ ] RAG stores split and loaded with ATT&CK
- [ ] First ATT&CK coverage report published
- [ ] Windows victim + Atomic Red Team
- [ ] Blue containerized into compose
- [ ] Write-up: lessons from deploying autonomous agents safely

## License

MIT. See [LICENSE](LICENSE).
