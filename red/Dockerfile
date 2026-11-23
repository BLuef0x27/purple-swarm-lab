FROM python:3.12-slim

ARG CAI_VERSION=""

# Recon tooling the agents can call. Keep this list short and deliberate.
RUN apt-get update \
 && apt-get install -y --no-install-recommends nmap curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Pin CAI: set CAI_VERSION in .env (e.g. 0.x.y) after checking PyPI.
RUN if [ -n "$CAI_VERSION" ]; then pip install --no-cache-dir "cai-framework==${CAI_VERSION}"; \
    else pip install --no-cache-dir cai-framework; fi

RUN useradd -m -u 10001 red
USER red
WORKDIR /home/red

CMD ["cai"]
