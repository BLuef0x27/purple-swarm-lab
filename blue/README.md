# Blue swarm: defensa_azul

[rsfl/defensa_azul](https://github.com/rsfl/defensa_azul) is a defensive agent control plane. Its policy gate denies by default, and agent output is only ever a proposal. All targets start in **observe mode**.

## Setup (bare first, containerize later)

```bash
cd blue
git clone https://github.com/rsfl/defensa_azul.git
cd defensa_azul
git checkout <pinned-commit>      # pin it; record the hash in docs/CHANGELOG.md
```

Read the launcher before you run it, then point it at local services:

- **Model:** Ollama at `http://ollama:11434` (from inside `llm-blue`), or `http://127.0.0.1:11434` if you temporarily publish it for bare testing
- **SIEM:** Splunk on `siem-net` (UI at `http://127.0.0.1:8000`)
- **Tokens:** two distinct random tokens (`openssl rand -hex 32`), kept in `blue/blue.env` (gitignored)

```bash
export DEFENSA_GATEWAY_TOKEN=...
export DEFENSA_ENDPOINT_TOKEN=...
export DEFENSA_GATEWAY_URL=https://127.0.0.1:<port>
./run_defensa_opencode.sh
```

## Rules

1. Get triage and incident reports working on real arena telemetry **before** enabling any response action.
2. Keep the operator token off endpoints.
3. The gateway binds to loopback. Reach it only through WireGuard or an SSH tunnel.
4. Once it works, add a `blue-defensa` service to `docker-compose.yml` on `llm-blue` + `siem-net` only.
