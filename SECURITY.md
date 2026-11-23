# Scope and Safety

This is a **lab**. Every offensive capability here targets only intentionally vulnerable containers on the internal `arena-net` Docker network, on hardware I own.

- Do not point any agent at systems you don't own or lack written permission to test.
- All agent networks are Docker `internal` networks with no route out of the host.
- No container mounts the Docker socket.
- Red never runs until the arena and blue are proven and `scripts/verify-isolation.sh` passes.

Found a containment flaw in this setup? Open an issue. That's exactly the kind of feedback this project is for.
