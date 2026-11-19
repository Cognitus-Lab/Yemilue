# Yemilue Wiki

Welcome to the **Yemilue** wiki — the portable workstation task & activity ML funnel.

> Yemilue quietly observes how you work (frontmost app, window title, typing rhythm, mouse activity, file saves, git commits) and distills it into clean, ML-ready training samples — **all on your machine, with zero data leaving it**.

## Contents
- [What is Yemilue?](#what-is-yemilue)
- [Quick start](#quick-start)
- [Architecture](#architecture)
- [The 8 event types](#the-8-event-types)
- [CLI reference](#cli-reference)
- [Building from source](#building-from-source)
- [Privacy & security](#privacy--security)
- [Troubleshooting](#troubleshooting)

---

## What is Yemilue?

Yemilue is a lightweight, cross-platform (macOS / Windows / Linux) **user-activity telemetry engine** written in Rust. It:

1. **Captures** how you work — frontmost application, window title, idle time, and interaction signals.
2. **Normalizes** raw signals into a fixed set of typed events.
3. **Funnels** those events into structured, ML-ready training samples you can export for model training.

It is deliberately **local-only**: nothing is transmitted over the network, and it never records key values or file contents — only the *patterns* of your activity.

---

## Quick start

### 1. Build
```bash
cd yemilue
cargo build --release
```

### 2. Run a capture session
```bash
# Capture for 60 seconds, watching your Projects folder
./target/release/yemilue run --duration 60 --watch ~/Projects
```

### 3. Inspect the output
```bash
# Print a human-readable summary of the last session
./target/release/yemilue info
```

### 4. Export ML-ready samples
```bash
# Export captured samples as JSON for training
./target/release/yemilue export --format json --out samples.json
```

> **macOS note:** On first run, grant Yemilue the *Accessibility* and *Screen Recording* permissions in **System Settings → Privacy & Security** so it can read the frontmost window title.

---

## Architecture

Yemilue is a small, single-binary engine with four cooperating layers:

```
�─────────────────────────────────────────────────────────�
│  Capture layer   (src/capture/)                          │
│  Polls the OS for frontmost app, window title, idle time │
�──────────────────────────�──────────────────────────────�
                           ▼
�─────────────────────────────────────────────────────────�
│  Event model     (src/events.rs)                        │
│  8 typed events: Focus, Input, Key, Click, Save,        │
│                 Commit, Idle, AppSwitch                  │
�──────────────────────────�──────────────────────────────�
                           ▼
�─────────────────────────────────────────────────────────�
│  Funnel          (src/funnel.rs)                        │
│  Thread-safe queue: normalizes + routes events          │
�──────────────────────────�──────────────────────────────�
                           ▼
�─────────────────────────────────────────────────────────�
│  Session         (src/session.rs)                       │
│  Accumulates a time-window of events → ML samples       │
�─────────────────────────────────────────────────────────�
```

**Design principles:**
- **Minimal surface** — one binary, no daemons, no network.
- **Typed events** — a fixed 8-event model keeps the output schema stable for ML.
- **Local-first** — all state lives on disk in your home directory.
- **Portable** — builds from a locked, vendored dependency set on all three OSes.

---

## The 8 event types

| # | Event | What it records |
|---|-------|-----------------|
| 1 | `WindowFocus` | An app/window came to the front (app name, title, timestamp) |
| 2 | `TextInput` | A burst of text entry (duration, approx. length) — **not the characters** |
| 3 | `KeyPress` | A discrete key / modifier interaction (count, timing) — **not the key value** |
| 4 | `MouseClick` | Click activity (count, position bucket, timing) |
| 5 | `FileSave` | A file was saved (path, timestamp) — **not the content** |
| 6 | `Commit` | A git commit was made (repo, hash, timestamp) |
| 7 | `Idle` | A period of no interaction (duration) |
| 8 | `AppSwitch` | The frontmost app changed (from → to, timestamp) |

> **Privacy note:** Yemilue records the *shape* of your activity (timing, counts, which app) but deliberately **never** records keystroke values, file contents, or credential data.

---

## CLI reference

```
yemilue [OPTIONS] <COMMAND>

Commands:
  run       Run a capture session for a given duration
  info      Print a summary of the most recent session
  export    Export captured samples to a file (json / csv)
  tree      Print a directory tree for a watched path

Options (global):
  --watch <PATH>     Directory to observe for file-save / commit events
  --duration <SECS>  How long a `run` session lasts (default: 60)
  --json             Emit machine-readable JSON output
```

### `run`
Starts a live capture session. Polls the OS on an internal tick and feeds events into the funnel until `--duration` elapses.
```bash
yemilue run --duration 120 --watch ~/code
```

### `info`
Shows the stats from the last completed session (event counts, sample count, top apps).
```bash
yemilue info
```

### `export`
Writes the accumulated ML samples to disk.
```bash
yemilue export --format json --out ~/ml/samples.json
```

### `tree`
Prints a readable directory tree (useful for choosing what to `--watch`).
```bash
yemilue tree ~/code/myproject
```

---

## Building from source

### Prerequisites
- **Rust** (stable, edition 2021) — `rustup` is the easiest way to install.
- **A C compiler** (for the platform FFI crates: `cocoa`/CoreGraphics on macOS, etc.).

### Build
```bash
cargo build --release
# Binary lands in target/release/yemilue
```

### Vendored / offline build
The project ships a `vendor/` directory and a `.cargo/deny.toml` that maps `crates-io → vendor`, so you can build **fully offline** with no network access:
```bash
cargo build --release --frozen
```

### Tests
```bash
cargo test
```

---

## Privacy & security

Yemilue is built around a strict local-only threat model. Full details live in [`SECURITY.md`](/blob/main/SECURITY.md).

**Guarantees:**
- **No network transmission** of captured data — zero outbound connections.
- **No keystroke values** — only activity patterns (counts, timing).
- **No file contents** — only save/commit events (path + timestamp).
- **No credential access** by design.

**Supply-chain controls:**
- All dependencies are **vendor-locked** and pinned in `Cargo.lock`.
- CI runs `cargo audit` (known CVEs) and `cargo deny` (license + source audit) on every push.
- Secret scanning runs on every commit (`.github/workflows/security.yml`).

**Contributor rules:** never add code that opens sockets, reads credential stores, or logs key values; any new dependency must be vendor-locked.

---

## Troubleshooting

**"Yemilue can't read the frontmost window on macOS."**
Grant **Accessibility** and **Screen Recording** in System Settings → Privacy & Security, then relaunch.

**Build fails with a network error."**
You're likely offline. Use the vendored build: `cargo build --release --frozen`.

**"cargo audit / cargo deny failed in CI."**
A dependency has a known advisory or a disallowed license. Update the crate in `Cargo.toml`, regenerate `Cargo.lock`, and commit both in the same PR.

**No samples are being produced."**
Make sure you're actually interacting with the machine during the session, and that `--watch` points at a directory where real file activity happens.

---

*Yemilue v0.1.0 — portable, local-only, ML-ready activity capture.*
