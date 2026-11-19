# � Yemilue

> **Ultra-lightweight, portable workstation task-capturing engine** — observes how you work across any desktop and streams structured, ML-ready training data out of the funnel.

Built in pure Rust with **zero runtime dependencies** beyond the OS itself. No daemons, no network calls, no telemetry upload: Yemilue runs locally, captures your activity in real time, and hands it to whatever model you want to train against.

---

## � What it does

Yemilue sits quietly on your workstation and, while you work:

1. **Captures** — polls the OS for the frontmost application, active window title, input activity, and system idle time. Works natively on **macOS**, **Windows**, and **Linux**.
2. **Types** — normalises every raw signal into one of 8 typed events:

   | Event | Meaning |
   |---|---|
   | `WindowFocus` | A window gained focus |
   | `AppSwitch` | You switched frontmost apps |
   | `TextInput` | Keyboard text was entered |
   | `KeyPress` | A key was pressed |
   | `MouseClick` | A click occurred |
   | `FileSave` | A file was saved in a watched dir |
   | `Commit` | A git commit was made in a watched repo |
   | `Idle` | The system sat unused past a threshold |

3. **Funnels** — a thread-safe queue normalises the raw events and routes them into the active session, so capture never blocks on processing.
4. **Streams** — emits clean, timestamped ML samples (JSONL) you can feed straight into a training run.

On exit it prints a clean summary of how many raw events were processed and how many ML samples were emitted.

---

## � Architecture

```
        �─────────────�   raw OS signals   �──────────�
        │  Capture    │ �─────────────────► │  Funnel  │
        │  (per-OS)   │                     │ (queue)  │
        �─────────────�                     �────�─────�
                                                  │ typed events
                                                  ▼
                                          �──────────────�
                                          │   Session    │
                                          �──────�───────�
                                                 │ ML samples (JSONL)
                                                 ▼
                                          �──────────────�
                                          │  Training    │
                                          �──────────────�
```

- **`src/capture/`** — platform adapters (CoreGraphics on macOS, Win32 on Windows, X11 on Linux).
- **`src/events.rs`** — the 8-event typed model.
- **`src/funnel.rs`** — lock-free normalisation & routing queue.
- **`src/session.rs`** — active session, sample emission, and final stats.
- **`src/main.rs`** — CLI entry point (banner, arg parsing, graceful shutdown).

---

## � Quick start

**Build**
```bash
cargo build --release
```

**Run**
```bash
# macOS
./run_macos.sh

# Linux
./run_linux.sh

# or run the binary directly
target/release/yemilue --duration 300 --watch ~/projects
```

**Key flags**
| Flag | Default | Purpose |
|---|---|---|
| `--duration` | `3600` | How long (seconds) to capture before a clean stop |
| `--watch` | `(cwd)` | Directory tree to monitor for file-save & git-commit events |
| `--out` | `./yemilue_samples.jsonl` | Where ML samples are written |
| `--idle-threshold` | `60` | Seconds of inactivity before an `Idle` event fires |

---

## � Requirements

- **Rust 1.70+** (edition 2021)
- One of: **macOS 12+**, **Windows 10+**, or a **Linux** distro with X11
- No external services, no API keys, no network access required

---

## � Privacy & security

- **Fully local** — every event stays on your machine. Nothing is transmitted anywhere.
- **No secrets captured** — Yemilue records window titles and activity *patterns*, not keystroke contents or file bodies.
- **Deterministic & inspectable** — the JSONL output is plain text you can read, filter, or delete at any time.
- **Graceful shutdown** — `Ctrl-C` flushes the funnel and prints final stats before exiting.

> �️ Yemilue is a local telemetry tool for *your own* workstation. Do not run it on machines you do not own or without the informed consent of the person using them.

---

## � License

**MIT** — see [`LICENSE`](./LICENSE).

```
MIT License
Copyright (c) 2026 GRRN-MAKER
```

---

## � Repo layout

```
yemilue/
�── Cargo.toml          # crate + binary definition (v0.1.0)
�── LICENSE             # MIT
�── README.md           # this file
�── run_macos.sh        # macOS launcher
�── run_linux.sh        # Linux launcher
�── src/
│   ├── main.rs         # CLI, banner, graceful shutdown
│   ├── events.rs       # 8 typed event model
│   ├── funnel.rs       # normalisation & routing queue
│   ├── session.rs      # active session + ML sample emission
│   �── capture/        # per-OS capture adapters
�── vendor/             # vendored crates (offline builds)
```

---

*Yemilue — see your work, train on it, own the data.*
