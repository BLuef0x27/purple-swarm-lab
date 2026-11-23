# Knowledge (RAG)

Three logical collections, split across **two separate Qdrant instances** so isolation is enforced by the network, not by naming:

| Collection | Lives in | Contents |
|---|---|---|
| `shared-reference` | Both (loaded read-only into each) | MITRE ATT&CK, CWE, public tool docs |
| `red-ops` | `qdrant-red` only | Attack notes, payloads, engagement history |
| `blue-ops` | `qdrant-blue` only | Detections, runbooks, incident reports |

**Why:** if both sides share one operational store, red learns how it gets caught and blue reads the answers before it detects anything. The coverage score would then measure leakage, not detection.

Embeddings: `nomic-embed-text` via the local Ollama. No outside API needed.

Source corpus downloads (ATT&CK STIX JSON, etc.) happen once, on the host, during setup. Store them in `rag/corpus/` and keep private material in `rag/corpus/private/` (gitignored).
