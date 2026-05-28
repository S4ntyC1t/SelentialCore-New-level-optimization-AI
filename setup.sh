#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Selential Core — Setup Script
# ─────────────────────────────────────────────────────────────
# Downloads the base model (Qwen3.5) and configures the build.
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh                # GPU (CUDA) — default
#   ./setup.sh --cpu          # CPU-only
#   ./setup.sh --big          # Full 35B model (24GB+ VRAM)
#   ./setup.sh --cpu --big    # CPU-only + big model
# ─────────────────────────────────────────────────────────────

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Selential Core — Setup                   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ── Parse arguments ──
USE_CUDA=true
USE_BIG=false
for arg in "$@"; do
    case "$arg" in
        --cpu) USE_CUDA=false ;;
        --big) USE_BIG=true   ;;
    esac
done

# ── Select model ──
if [ "$USE_BIG" = true ]; then
    MODEL_REPO="Qwen/Qwen3.5-35B-A3B-UD-GGUF"
    MODEL_FILENAME="qwen3.5-35b-a3b-ud-q4_k_m.gguf"
    MODEL_FILE="Qwen3.5-35B-A3B-UD-Q4_K_M.gguf"
    MODEL_SIZE="22 GB"
    MIN_VRAM=24
else
    MODEL_REPO="Qwen/Qwen3.5-0.8B-GGUF"
    MODEL_FILENAME="qwen3.5-0.8b-q4_k_m.gguf"
    MODEL_FILE="Qwen3.5-0.8B-Q4_K_M.gguf"
    MODEL_SIZE="508 MB"
    MIN_VRAM=2
fi

MODEL_URL="https://huggingface.co/${MODEL_REPO}/resolve/main/${MODEL_FILENAME}"

# ── Check prerequisites ──
echo -e "${YELLOW}[1/3] Checking prerequisites...${NC}"

if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required. Install it with: sudo apt install curl${NC}"
    exit 1
fi

if ! command -v cargo &> /dev/null; then
    echo -e "${RED}Error: Rust/Cargo not found. Install: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh${NC}"
    exit 1
fi

# ── Configure CUDA feature in Cargo.toml ──
echo ""
echo -e "${YELLOW}[2/3] Configuring build...${NC}"

if [ "$USE_CUDA" = true ]; then
    if command -v nvcc &> /dev/null; then
        echo -e "${GREEN}  ✅ CUDA toolkit found${NC}"
        # Ensure CUDA feature is enabled in Cargo.toml
        if grep -q 'features = \["cuda"\]' Cargo.toml; then
            echo -e "  CUDA feature already enabled"
        else
            echo -e "  Enabling CUDA feature..."
            sed -i 's/llama-cpp-2 = { version = "0.1"/llama-cpp-2 = { version = "0.1", features = ["cuda"]/' Cargo.toml
            sed -i 's/llama-cpp-sys-2 = { version = "0.1"/llama-cpp-sys-2 = { version = "0.1", features = ["cuda"]/' Cargo.toml
        fi
    else
        echo -e "${YELLOW}  ⚠️  nvcc not found — falling back to CPU${NC}"
        # Remove CUDA feature
        sed -i 's/, features = \["cuda"\]//g' Cargo.toml
        USE_CUDA=false
    fi
else
    echo -e "${YELLOW}  CPU-only build (no CUDA overhead)${NC}"
    # Remove CUDA feature for CPU-only compilation
    sed -i 's/, features = \["cuda"\]//g' Cargo.toml
fi

# ── Download model ──
echo ""
echo -e "${YELLOW}[3/3] Downloading model (~${MODEL_SIZE})...${NC}"
echo -e "${CYAN}  ${MODEL_FILE}${NC}"
echo ""

if [ -f "$MODEL_FILE" ]; then
    echo -e "${GREEN}  ✅ Already exists: ${MODEL_FILE}${NC}"
else
    echo -e "  Downloading from HuggingFace..."
    echo -e "  ${MODEL_URL}"
    echo ""
    curl -L --progress-bar -o "$MODEL_FILE" "$MODEL_URL"
    echo -e "${GREEN}  ✅ Downloaded: ${MODEL_FILE}${NC}"
fi

# ── Done ──
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Setup Complete!                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  📦 Model: ${MODEL_FILE}"
echo -e "  🖥️  Mode: $([ "$USE_CUDA" = true ] && echo 'GPU (CUDA)' || echo 'CPU')"
echo ""
echo -e "  ${CYAN}Next:${NC}"
echo -e "    cargo run --release -- interactive"
echo ""
