#!/bin/bash
# filepath: experiment1_fuzzing/run_fuzzing.sh

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_instrumented_binary>"
    exit 1
fi

TARGET_BINARY=$1
INPUT_DIR="./corpus/seeds"
SANITIZED_INPUT_DIR="./corpus/sanitized_seeds"
OUTPUT_DIR="./fuzzing_output_$(date +%Y%m%d_%H%M%S)"
TIMEOUT="5000"

if [ ! -f "$TARGET_BINARY" ]; then
    echo "Error: Target binary not found at $TARGET_BINARY"
    exit 1
fi

if [ ! -d "$INPUT_DIR" ] || [ -z "$(ls -A "$INPUT_DIR")" ]; then
    echo "Error: Input seed directory not found or is empty."
    exit 1
fi

echo "[*] Starting seed sanitation..."
rm -rf "$SANITIZED_INPUT_DIR"
mkdir -p "$SANITIZED_INPUT_DIR"

GOOD_SEEDS=0
BAD_SEEDS=0

for seed in "$INPUT_DIR"/*; do
    echo -n "  -> Testing seed: $(basename "$seed")... "
    if "$TARGET_BINARY" "$seed" &> /dev/null; then
        echo "OK"
        cp "$seed" "$SANITIZED_INPUT_DIR/"
        ((GOOD_SEEDS++))
    else
        echo "FAIL (crashes)"
        ((BAD_SEEDS++))
    fi
done

echo "[+] Sanitation complete. Kept $GOOD_SEEDS seeds, removed $BAD_SEEDS crashing seeds."

if [ "$GOOD_SEEDS" -eq 0 ]; then
    echo "[!] Error: No valid seeds survived sanitation. Cannot start fuzzing."
    rm -rf "$SANITIZED_INPUT_DIR"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

export AFL_SKIP_CPUFREQ=1
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1

echo "Starting AFL++ fuzzing..."
echo "  Target: $TARGET_BINARY"
echo "  Sanitized Input: $SANITIZED_INPUT_DIR"
echo "  Output: $OUTPUT_DIR"
echo "Press Ctrl+C to stop fuzzing"
echo ""

afl-fuzz -i "$SANITIZED_INPUT_DIR"          -o "$OUTPUT_DIR"          -t "$TIMEOUT"          -m none          -- "$TARGET_BINARY" @@

echo ""
echo "Fuzzing stopped. Results in: $OUTPUT_DIR"

CRASHES_DIR="$OUTPUT_DIR/default/crashes"

if [ -d "$CRASHES_DIR" ] && [ "$(ls -A "$CRASHES_DIR")" ]; then
    CRASH_COUNT=$(find "$CRASHES_DIR" -type f -name "id:*" | wc -l)
    echo "Found $CRASH_COUNT crashes."
    mkdir -p ./results/crashes/
    cp "$CRASHES_DIR"/id:* ./results/crashes/
    echo "Crashes copied to results/crashes/"
else
    echo "No crashes found."
    read -p "Would you like to manually provide another interesting input file (e.g., from /queue or /hangs)? (y/N): " user_choice
    if [[ "$user_choice" =~ ^[Yy]$ ]]; then
        read -e -p "Enter the FULL PATH to the alternative input file or directory: " alt_input
    if [ -f "$alt_input" ]; then
        mkdir -p ./results/crashes/
        cp "$alt_input" ./results/crashes/manual_input
        echo "[+] Alternative input copied to results/crashes/manual_input"
    elif [ -d "$alt_input" ]; then
        mkdir -p ./results/crashes/
        cp "$alt_input"/* ./results/crashes/
        echo "[+] All files from directory copied to results/crashes/"
    else
        echo "[-] Path not found or not a valid file/directory: $alt_input. Skipping."
    fi
        fi
    fi
fi

rm -rf "$SANITIZED_INPUT_DIR"
echo "[*] Cleaned up sanitized seeds directory."
