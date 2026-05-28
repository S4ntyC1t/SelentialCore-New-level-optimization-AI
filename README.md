<div align="center">

# ⚡ Selential Core

### MoLoRA Inference Engine — Runtime-Hot-Swappable LoRA Adapters for Qwen

[![Rust](https://img.shields.io/badge/Rust-1.75%2B-orange)](https://www.rust-lang.org)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

</div>

**Selential Core** is a **Rust-native inference engine** for the [Qwen3.5](https://github.com/QwenLM/Qwen) family of models. It implements **MoLoRA (Mixture of LoRA Experts)** — a technique that extracts individual MoE experts from Qwen's transformer layers, compresses them via SVD into LoRA adapters, and hot-swaps them at runtime based on the query type.

Instead of one model doing everything, Selential builds an **orchestra of specialists**: a generalist core + coding experts for structural code, flow/error handling, and system I/O.

---

## 🚀 Quick Start

### Prerequisites

- **Rust** 1.75+ (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- **4GB+ RAM** (8GB+ recommended)
- **Optional:** NVIDIA GPU with CUDA 12+ for acceleration

### Setup

```bash
# 1. Clone
git clone https://github.com/S4ntyC1t/SelentialCore-New-level-optimization-AI.git
cd SelentialCore-New-level-optimization-AI

# 2. Download the model + tokenizer
chmod +x setup.sh
./setup.sh

# 3. Build & run
cargo run --release -- interactive
```

For GPU acceleration:
```bash
./setup.sh --cuda
cargo run --release -- interactive
```

For the full 35B model (24GB+ VRAM):
```bash
./setup.sh --big
cargo run --release -- interactive
```

---

## 🎯 Features

| Feature | Description |
|---|---|
| **MoLoRA Orchestras** | Query automatically routes to the right expert combo |
| **Hot-Swap Adapters** | Switch between coding domains mid-conversation |
| **Hashtag Routing** | `#struct #match #io` — or just describe what you need |
| **KB Cache** | Semantic cache for repeated queries (instant response) |
| **Chat History** | Full multi-turn conversation with context |
| **Russian Support** | Detects Russian queries, translates internally, responds naturally |
| **KV-Cache Quantization** | Q4_0 KV-cache saves ~75% VRAM |

### Expert Orchestra Architecture

```
User Query
   │
   ├─🌐 Generalist Core (#70)        ← always active
   │     Syntax, logic, coherence
   │
   └─🎯 Coding Specialists (by topic)
         │
         ├─🏗️  Structural — #164, #92
         │     struct, impl, trait, generics
         │
         ├─🔀 Flow & Error — #116, #115
         │     match, Result, Option, concurrency
         │
         └─📁 System & IO — #172, #116
               File, HashMap, iterators
```

---

## 💻 Usage

### Interactive Mode

```bash
cargo run --release -- interactive
```

Type anything — the engine detects what you need and routes to the right expert:

```
> Implement a generic binary search tree in Rust

  🏷️  #algorithms #struct #trait #make

[🏗️ structural]
// Here's a generic BST implementation...
```

### Commands

| Command | Description |
|---|---|
| `/help` | Show all commands |
| `/orchestra` | Show current expert orchestra |
| `/tags` | List routing hashtags |
| `/hashtags <query>` | Preview hashtag routing |
| `/stats` | Session statistics |
| `/reset` | Clear conversation |
| `/exit` | Quit |

### Single Prompt Mode

```bash
cargo run --release -- prompt "Write a thread-safe HashMap wrapper in Rust"
cargo run --release -- prompt "#struct #io Implement a BufReader line counter" -e structural
```

---

## 🧠 How It Works

### Expert Extraction

1. **Probe phase:** Analyze Qwen3.5-35B's 256 MoE experts using activation patterns on coding, reasoning, and chat queries
2. **Selection:** Pick the most specialized experts per sub-domain (probe → cosine similarity)
3. **SVD Compression:** Compress each expert's weights (3× matrices: gate, up, down) into rank-16 LoRA adapters
4. **GGUF conversion:** Merge selected experts into orchestrated GGUF files for llama.cpp

### Inference Pipeline

```
Query → Hashtag Extraction → Language Detection → KB Cache Lookup
                                                     ↓ (miss)
                                              Router (keyword + hashtag) → Select Expert
                                                                              ↓
                                          ChatML Prompt Builder → llama.cpp (GGUF LoRA)
```

---

## 🏗️ Project Structure

```
├── src/
│   ├── main.rs          # CLI entry point
│   ├── engine.rs        # llama.cpp inference engine
│   ├── inference.rs     # High-level inference pipeline
│   ├── pipeline.rs      # Preprocess → Route → Generate flow
│   ├── router.rs        # Keyword + hashtag-based routing
│   ├── hashtags.rs      # Semantic hashtag extraction
│   ├── config.rs        # Configuration + expert definitions
│   ├── kb.rs            # Knowledge base semantic cache
│   ├── translator.rs    # Russian → English translation
├── adapters/            # GGUF LoRA adapters (orchestra files)
├── tokenizers/          # Qwen tokenizer
├── training/            # Python scripts for expert extraction
├── Cargo.toml
└── setup.sh             # Model download script
```

---

## 🔬 Performance

| Configuration | VRAM | t/s (vs baseline) |
|---|---|---|
| **Baseline** (no LoRA) | 0.91 GB | 9.7 tok/s |
| **1 expert** | +28 MB | -13% |
| **2 experts** | +17 MB | -10% |
| **3 experts** | +22 MB | -10% |

LoRA experts add only **~17-28 MB VRAM** with **~10% speed impact** — negligible overhead for specialist capabilities.

---

## 🛠️ Building from Source

### CPU-only (no CUDA)

```bash
# Edit Cargo.toml: remove "cuda" feature from llama-cpp-2 deps
# Then build:
cargo build --release
```

### GPU (CUDA)

```bash
# Requirements: CUDA 12+, cuBLAS
./setup.sh --cuda
cargo build --release
```

### Full 35B Model

```bash
./setup.sh --big
# Edit src/config.rs → update base_model_path to the 35B GGUF
# Edit inference.rs → set n_gpu_layers to 25+ (depends on your VRAM)
cargo run --release -- interactive
```

---

## 📊 Probe Results

From our full probe of all 256 MoE experts in Qwen3.5-35B:

| Category | Count | % |
|---|---|---|
| **Active experts** | 208 | 81.2% |
| **Coding specialists** | 70 | 27.3% |
| **Generalists** | 138 | 53.9% |
| **Low-activity** | 48 | 18.8% |

Qwen's MoE is **well-designed** — 81% of experts actively contribute. The coding-specific experts (70 total) were our focus for the orchestra architecture.

---

## 🔗 Links

- [Qwen3.5 on HuggingFace](https://huggingface.co/Qwen/Qwen3.5-35B-A3B-UD-GGUF)
- [llama.cpp](https://github.com/ggml-ai/llama.cpp)
- [llama-cpp-2 (Rust bindings)](https://crates.io/crates/llama-cpp-2)

---

<div align="center">

**Built with ❤️ using Rust + llama.cpp**

</div>
