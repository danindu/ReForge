#!/bin/bash
# setup_custom_model.sh - Create a custom Ollama model for exploit analysis
# Following the YouTube video methodology

set -e

MODEL_NAME="reforge-gpt"
BASE_MODEL="llama2:7b-chat-q4_0"  # Using memory-optimized model
MODELFILE_PATH="./modelfile"

echo "=== Setting up Custom Exploit Analysis Model ==="
echo ""

# Check if Ollama is running
echo "[*] Checking Ollama server status..."
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo "[*] Starting Ollama server..."
    ollama serve &
    OLLAMA_PID=$!
    echo "Ollama PID: $OLLAMA_PID"
    
    # Wait for Ollama to be ready with better checking
    echo "[*] Waiting for Ollama to initialize..."
    for i in {1..60}; do
        if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
            echo "[+] Ollama server is ready!"
            break
        fi
        echo "    Waiting for Ollama... ($i/60)"
        sleep 2
    done
    
    # Final check
    if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo "[-] Failed to start Ollama server after 120 seconds"
        exit 1
    fi
else
    echo "[+] Ollama server is already running"
fi

# Check if base model exists
echo "[*] Checking for base model: $BASE_MODEL"
if ! ollama list | grep -q "$BASE_MODEL"; then
    echo "[*] Base model not found. Downloading $BASE_MODEL..."
    echo "    This may take several minutes..."
    if ollama pull "$BASE_MODEL"; then
        echo "[+] Base model downloaded successfully!"
    else
        echo "[-] Failed to download base model"
        exit 1
    fi
else
    echo "[+] Base model $BASE_MODEL is available"
fi

# Check if Modelfile exists
if [ ! -f "$MODELFILE_PATH" ]; then
    echo "[-] Error: Modelfile not found at $MODELFILE_PATH"
    echo "    Creating Modelfile..."
    
    cat > "$MODELFILE_PATH" << 'EOF'
FROM llama2:7b-chat-q4_0

PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER num_ctx 3072
PARAMETER num_predict 1500
PARAMETER repeat_penalty 1.1

SYSTEM """You are a cybersecurity educator specializing in exploit analysis. You MUST follow this exact 5-section format for EVERY analysis:

## 1. What is this exploit?
- Brief summary of what the exploit does
- Type of vulnerability it targets (buffer overflow, RCE, etc.)

## 2. How does the python script (PoC) work?
- Step-by-step breakdown of the exploit process
- What behavior to expect when run (crash, shell, command execution)
- Any limitations or assumptions
- Key components and their purposes

## 3. Technical Details:
- Buffer overflow mechanics (if applicable)
- Payload structure and significance
- Target binary interaction
- Memory layout considerations

## 4. Impact and Risks:
- What happens when this exploit runs successfully
- Potential damage or consequences
- Why this vulnerability is dangerous
- Real-world attack scenarios

## 5. Detection and Prevention:
- How to detect such attacks
- Mitigation strategies (ASLR, DEP, stack canaries)
- Best practices for prevention
- Secure coding recommendations

IMPORTANT RULES:
- ALWAYS use the exact section headers above with ##
- Complete ALL 5 sections - never stop early
- Write 2-3 sentences minimum per subsection
- Use clear, beginner-friendly language (CompTIA Security+ level)
- Format response in proper markdown
- Be thorough and complete your analysis

"""
EOF
    
    echo "[+] Modelfile created successfully!"
fi

# Remove existing custom model if it exists
if ollama list | grep -q "$MODEL_NAME"; then
    echo "[*] Removing existing custom model..."
    ollama rm "$MODEL_NAME" || true
fi

# Create the custom model from Modelfile
echo "[*] Creating custom model: $MODEL_NAME"
echo "    This may take a few minutes..."

if ollama create "$MODEL_NAME" -f "$MODELFILE_PATH"; then
    echo "[+] Custom model '$MODEL_NAME' created successfully!"
else
    echo "[-] Failed to create custom model"
    echo "    Checking Modelfile syntax..."
    cat "$MODELFILE_PATH"
    exit 1
fi

# Test the custom model
echo "[*] Testing the custom model..."
echo "Available models:"
ollama list

echo ""
echo "[*] Testing custom model with a simple query..."
echo "Response:"
echo "Analyze this simple buffer overflow: char buf[10]; strcpy(buf, user_input);" | ollama run "$MODEL_NAME" || {
    echo "[-] Model test failed"
    exit 1
}

echo ""
echo "=== Setup Complete ==="
echo "Your custom exploit analysis model '$MODEL_NAME' is ready!"
echo ""
echo "Usage:"
echo "  ollama run $MODEL_NAME"
echo "  python3 api_handlers/ollama_handler.py <exploit_file>"
echo ""