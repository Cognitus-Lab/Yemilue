# Yemilue Security Policy

## Scope
Yemilue is a **local-only** workstation telemetry engine. This policy documents what the project does and does **not** do with data, and the controls that keep it safe.

## Data handling guarantees
| Property | Status |
|---|---|
| Network transmission of captured data | **None** — all events stay on the local machine |
| Keystroke content capture | **No** — only activity *patterns* (counts, timing), never key values |
| File content capture | **No** — only save/commit *events* (path + timestamp), never file bodies |
| Credential / secret capture | **No** — Yemilue has no credential access by design |
| Telemetry upload / phoning home | **None** — zero outbound connections |

## Threat model & mitigations
| Risk | Mitigation |
|---|---|
| Malicious dependency injection | All third-party crates are **vendor-locked** in `vendor/` and pinned in `Cargo.lock`; no network fetch at build time |
| Uncontrolled build | CI builds from a locked dependency set; `cargo build --frozen` in the pipeline |
| Supply-chain (typosquat) | Dependency audit on every push (see `security.yml`) |
| Overly-broad file access | Capture is scoped to an explicit `--watch` directory; nothing outside it is read |
| Sensitive repo capture | Users exclude secrets dirs (`.env`, `id_rsa`, keychains) from `--watch` paths |

## Required practices for contributors
1. **Never** add code that opens sockets, reads credential stores, or logs key values.
2. **Never** add a runtime dependency that phones home; new crates must be vendor-locked.
3. Keep `Cargo.lock` committed and updated in the same PR as any dependency change.
4. Any new capture adapter must respect the 8-event typed model and emit no raw content.

## Automated security checks (CI)
- `cargo audit` — known-vulnerability scan of the locked dependency tree on every push.
- `cargo deny` — license + source audit (no unexpected / unlicensed crates).
- Secret scanning on every commit.

## Incident response
1. Identify the affected dependency or code path.
2. Pin / revert the change; update `Cargo.lock`.
3. Re-run the full security CI (`cargo audit && cargo deny check`).
4. Tag a patched release and note the fix in the changelog.

---
*Last updated: 2026 — Yemilue v0.1.0*
