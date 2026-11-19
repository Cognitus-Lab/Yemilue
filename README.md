# � Yemilue

> **Ultra-lightweight, portable workstation task-capturing engine and real-time ML dataset pipeline written in pure Rust, zero-dependency, cross-platform (macOS / Windows / Linux), and flash-drive portable with no Rust toolchain required on the target machine (pre-compiled binaries included for all three platforms). V1.0.1**

`Yemilue` runs natively in the background on your workstation (or portable flash drive) with **zero external dependencies** and minimal overhead (~362 KB compiled release binary, <5 MB RAM, 0% idle CPU). It passively captures user tasks, active window titles, application switches, typing cadence, and focus/idle transitions, immediately converting them through a **Unified Data Funnel** into streamable, machine-learning-ready datasets (`JSONL` and `CSV`).

---

## �️ Architecture: Unified Data Funnel

```
�────────────────────────────────────────────────────────────────────────�
│                      NATIVE OS ACTIVITY HOOKS                          │
│     macOS (AppKit / CoreGraphics) | Windows (Win32) | Linux (X11)      │
�──────────────────────────────────�─────────────────────────────────────�
                                   │ RawEvent
                                   ▼
�────────────────────────────────────────────────────────────────────────�
│                        UNIFIED FUNNEL PIPELINE                         │
│                                                                        │
│   1. Event Normalizer                                                  │
│      Normalizes events across OS boundaries into standard schema.      │
│                                                                        │
│   2. Session Manager (session.rs)                                      │
│      Groups micro-events into logical task sessions; auto-forks        │
│      sessions on idle threshold (>300s).                               │
│                                                                        │
│   3. Feature Extractor (features.rs)                                   │
│      Calculates ML feature tensors (focus entropy, one-hot app         │
│      categories, typing cadence, switch frequencies, work-hour flags). │
│                                                                        │
│   4. Output Writer (output.rs)                                         │
│      Streams UnifiedTaskRecords with immediate atomic flushes to disk. │
�──────────────────────────────────�─────────────────────────────────────�
                                   │
                                   ▼
             `tasks_ml_dataset.jsonl` / `tasks_ml_dataset.csv`
```

---

## � Quick Start

### 1. Build the Standalone Binary (only needed on the build machine)
```bash
cargo build --release
```
The optimized release binary is located at `target/release/yemilue` (~362 KB).

### 2. Run the Engine
```bash
# Basic run (streams to tasks_ml_dataset.jsonl)
./target/release/yemilue

# Custom JSONL path + Dual CSV export with 250ms polling interval
./target/release/yemilue --output my_dataset.jsonl --csv my_dataset.csv --interval 250
```

### CLI Options:
* `-o, --output <FILE>`: Path to output JSONL dataset (default: `tasks_ml_dataset.jsonl`)
* `--csv <FILE>`: Enable simultaneous CSV dataset stream (default: disabled)
* `-i, --interval <MS>`: Hook polling interval in milliseconds (default: `500`)
* `-h, --help`: Display help information

---

## � Dataset Schema

Each entry in `tasks_ml_dataset.jsonl` contains:

```json
{
  "metadata": {
    "version": 1,
    "timestamp": 1791822342,
    "platform": "macos",
    "engine_version": "1.0.1",
    "arch": "aarch64"
  },
  "session": {
    "session_id": "sess_000001",
    "duration_secs": 185.0,
    "current_app": "Code",
    "focused_time": 0.88,
    "idle_time": 22.0,
    "switches": 3,
    "typing_speed": 72.5,
    "total_clicks": 48
  },
  "ml_sample": {
    "features": {
      "hour_of_day": 14,
      "day_of_week": 2,
      "time_since_last_switch": 45.2,
      "session_duration": 185.0,
      "typing_speed": 72.5,
      "apps_in_rotation": 2,
      "focus_entropy": 0.366,
      "idle_ratio": 0.12,
      "app_categories": [0.65, 0.35, 0.0, 0.0, 0.0, 0.0, 0.0],
      "time_of_day_bin": 1,
      "is_work_hours": 1,
      "switch_frequency": 0.97,
      "click_rate": 15.5
    },
    "labels": {
      "next_action": "Code",
      "productivity_score": 0.88,
      "task_completion_probability": 0.836
    }
  }
}
```

---

## � Loading into PyTorch Training Pipeline

```python
import json
import torch
from torch.utils.data import Dataset, DataLoader

class TaskDataset(Dataset):
    def __init__(self, jsonl_path: str):
        self.samples = []
        with open(jsonl_path, "r", encoding="utf-8") as f:
            for line in f:
                if line.strip():
                    self.samples.append(json.loads(line))

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        item = self.samples[idx]["ml_sample"]
        feats = item["features"]
        
        # Construct feature vector
        x = torch.tensor([
            feats["hour_of_day"] / 24.0,
            feats["day_of_week"] / 7.0,
            feats["session_duration"] / 3600.0,
            feats["typing_speed"] / 150.0,
            feats["focus_entropy"],
            feats["idle_ratio"],
            feats["is_work_hours"],
            feats["switch_frequency"],
            feats["click_rate"],
            *feats["app_categories"]
        ], dtype=torch.float32)

        # Labels
        y_productivity = torch.tensor(item["labels"]["productivity_score"], dtype=torch.float32)
        y_completion = torch.tensor(item["labels"]["task_completion_probability"], dtype=torch.float32)

        return x, y_productivity, y_completion

# Example usage
loader = DataLoader(TaskDataset("tasks_ml_dataset.jsonl"), batch_size=32, shuffle=True)
```

---

## � Tests

```bash
cargo test
```
Verifies event serialization, session lifecycle management, app categorization, feature extraction, and native OS telemetry.

---

## � Running from Flash Drive on Any PC (V1.0.1 — pre-compiled binaries included)

Copy the entire `Yemilue` folder onto your flash drive. **No Rust installation needed** on the target machine — pre-compiled binaries for all three platforms are included:

* `yemilue` — macOS (Universal: Apple Silicon + Intel)
* `yemilue.exe` — Windows (x64)
* `yemilue_linux` — Linux (static, x86_64)

### � On macOS (Apple Silicon M1/M2/M3/M4 & Intel x86_64)
- **Finder:** Double-click `run_macos.command` directly in Finder.
- **Terminal:**
  ```bash
  ./run_macos.sh -o my_dataset.jsonl --csv my_dataset.csv
  ```

### � On Windows
- Double-click or run:
  ```cmd
  run_windows.bat -o my_dataset.jsonl
  ```

### � On Linux
- Run:
  ```bash
  ./run_linux.sh -o my_dataset.jsonl
  ```
