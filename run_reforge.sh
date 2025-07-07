#!/bin/bash
# run_all_experiments.sh - Master script for the automated exploit framework (patched July 2025).

set -e

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"
CUSTOM_MODEL="reforge-gpt"

# --- Global Variables ---
TARGET_INSTRUMENTED_BIN=""
TARGET_UNINSTRUMENTED_BIN=""

# --- Banner ---
print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  AI‑Powered Fuzzing, Exploit Generation & Explanation Pipeline ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# --- Prerequisite Checks ---
check_prerequisites() {
    echo -e "${YELLOW}[*] Checking prerequisites...${NC}"
    local errors=0

    command -v afl-fuzz &>/dev/null || { echo -e "${RED}  ✗ AFL++ not installed${NC}"; ((errors++)); }
    command -v python3 &>/dev/null || { echo -e "${RED}  ✗ Python3 not installed${NC}"; ((errors++)); }
    command -v ollama &>/dev/null || { echo -e "${RED}  ✗ Ollama CLI not installed${NC}"; ((errors++)); }

    # Start Ollama server if needed
    if command -v ollama &>/dev/null; then
        if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
            echo -e "${YELLOW}  ⚠ Ollama not running. Starting Ollama server...${NC}"
            (ollama serve >/dev/null 2>&1 &) && sleep 3
        fi
        curl -s http://localhost:11434/api/tags >/dev/null 2>&1 || { echo -e "${RED}  ✗ Failed to start Ollama server${NC}"; ((errors++)); }
    fi

    # API keys
    if [ -f .env ]; then
        source .env
        [ -z "$AI_API_KEY" ] && { echo -e "${RED}  ✗ AI_API_KEY not set in .env${NC}"; ((errors++)); }
    else
        echo -e "${RED}  ✗ .env file not found${NC}"
        ((errors++))
    fi

    if [ $errors -gt 0 ]; then
        echo -e "${RED}[!] Prerequisites check failed. Resolve above issues and retry.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[+] All prerequisites satisfied${NC}"
}

# --- Custom Model Setup (unchanged, condensed) ---
setup_custom_model() {
    echo -e "${YELLOW}[*] Ensuring custom ReForge-GPT model is available...${NC}"
    if ! ollama list | grep -q "$CUSTOM_MODEL"; then
        echo -e "${YELLOW}[~] Building custom model...${NC}"
        bash "$SCRIPT_DIR/setup_custom_model.sh"
    fi
}

# --- Experiment 1: AFL++ Fuzzing ---
run_experiment1() {
    echo -e "${BLUE}════════════ EXPERIMENT 1: FUZZING ════════════${NC}"

    if [ -d "$RESULTS_DIR/crashes" ] && [ -n "$(ls -A "$RESULTS_DIR/crashes" 2>/dev/null)" ]; then
        echo -e "${YELLOW}[*] Existing crashes detected in results/crashes${NC}"
        read -p "Skip fuzzing and reuse existing crashes? (y/N): " yn
        if [[ "$yn" =~ ^[Yy]$ ]]; then
            read -p "Path to UNinstrumented binary: " TARGET_UNINSTRUMENTED_BIN
            if [ ! -f "$TARGET_UNINSTRUMENTED_BIN" ]; then
                echo -e "${RED}Binary not found${NC}"; exit 1
            fi
            return 0
        else
            rm -rf "$RESULTS_DIR"
        fi
    fi

    mkdir -p "$RESULTS_DIR"/{crashes,exploits,reports}

    read -p "Path to INstrumented binary: " TARGET_INSTRUMENTED_BIN
    read -p "Path to UNinstrumented binary: " TARGET_UNINSTRUMENTED_BIN

    for f in "$TARGET_INSTRUMENTED_BIN" "$TARGET_UNINSTRUMENTED_BIN"; do
        [ -f "$f" ] || { echo -e "${RED}File $f not found${NC}"; exit 1; }
    done

    echo -e "${YELLOW}[*] Launching AFL++...${NC}"
    trap 'echo -e "${YELLOW}
[*] Fuzzing interrupted – continuing pipeline...${NC}"' INT
    ./run_fuzzing.sh "$TARGET_INSTRUMENTED_BIN" || true
}

# --- Experiment 2: Exploit Generation & Explanation ---
run_experiment2() {
    echo -e "${BLUE}════════════ EXPERIMENT 2: AI EXPLOITS & ANALYSIS ════════════${NC}"

    # Loop over every crash file
    for crash_file in "$RESULTS_DIR/crashes"/*; do
        [ -f "$crash_file" ] || continue
        echo -e "${YELLOW}[*] Processing $(basename "$crash_file")${NC}"

        exploit_file="$RESULTS_DIR/exploits/exploit_$(basename "$crash_file").py"
        mkdir -p "$(dirname "$exploit_file")"

        echo -e "${YELLOW}[*] Generating exploit with AI...${NC}"
        if python3 "$SCRIPT_DIR/api_handlers/openai_handler.py" "$crash_file" "$TARGET_UNINSTRUMENTED_BIN" > "$exploit_file"; then
            echo -e "${GREEN}[+] Exploit saved to $exploit_file${NC}"
        else
            echo -e "${RED}[!] Exploit generation failed for $(basename "$crash_file")${NC}"
            continue
        fi

        echo -e "${YELLOW}[*] Validating exploit...${NC}"
        if python3 "$SCRIPT_DIR/utils/exploit_validator.py" "$exploit_file" "$TARGET_UNINSTRUMENTED_BIN" | grep -q "SUCCESS"; then
            echo -e "${GREEN}[+] Validation success${NC}"
        else
            echo -e "${YELLOW}[!] Validation failed – continuing anyway${NC}"
        fi

        echo -e "${YELLOW}[*] Generating LLaMA2 analysis...${NC}"
        report_file="$RESULTS_DIR/reports/$(basename "$crash_file").md"
        python3 "$SCRIPT_DIR/api_handlers/ollama_handler.py" "$exploit_file" "$crash_file" > "$report_file"
        echo -e "${GREEN}[+] Analysis saved to $report_file${NC}"
    done
}

main() {
    print_banner
    check_prerequisites
    setup_custom_model
    mkdir -p "$RESULTS_DIR"/{crashes,exploits,reports}

    run_experiment1
    run_experiment2

    echo -e "${GREEN}All steps completed. Check results/ directory.${NC}"
}

main
