#!/usr/bin/env python3
"""Local Ollama Handler (patched) — explains exploit with custom LLaMA2."""
import os, sys, requests, json
from colorama import Fore, Style

class OllamaHandler:
    def __init__(self, model="reforge-gpt", host="http://localhost:11434"):
        self.model = model
        self.host = host.rstrip("/")
        self.api_url = f"{self.host}/api/generate"
        if not self._alive():
            raise ConnectionError("Ollama server not reachable at " + self.host)

    def _alive(self):
        try:
            return requests.get(f"{self.host}/api/tags", timeout=5).status_code == 200
        except requests.RequestException:
            return False

    def explain(self, exploit_code: str, crash_hex: str, binary_name: str = "Unknown"):
        prompt = f"""You are an exploit analyst. You will receive:

### Crash Input (hex):
```
{crash_hex}
```

### Exploit Script (Python):
```python
{exploit_code}
```

Explain in **simple terms**:
1. What the crash input looks like and which bytes likely trigger the crash.
2. How the Python script reproduces the crash.
3. Likely reason for the crash (only based on provided data).

Do **NOT** mention mitigations, ROP, shellcode, or external tools unless visible in the code.
Output 2‑3 concise paragraphs, beginner‑friendly."""

        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {"temperature": 0.3, "top_p": 0.9, "num_ctx": 2048}
        }
        response = requests.post(self.api_url, json=payload, timeout=600)
        if response.status_code != 200:
            raise RuntimeError("Ollama error: " + response.text)
        print(response.json().get("response", ""))

def main():
    if len(sys.argv) < 2:
        print("Usage: {} <exploit.py> [crash_file]".format(sys.argv[0]), file=sys.stderr)
        sys.exit(1)

    exploit_path = sys.argv[1]
    crash_path = sys.argv[2] if len(sys.argv) > 2 else None

    with open(exploit_path, "r") as f:
        exploit_code = f.read()

    crash_hex = ""
    if crash_path and os.path.exists(crash_path):
        with open(crash_path, "rb") as f:
            crash_hex = f.read().hex()

    handler = OllamaHandler(model=os.getenv("REFORGE_MODEL", "reforge-gpt"), host=os.getenv("OLLAMA_HOST", "http://localhost:11434"))
    handler.explain(exploit_code, crash_hex)

if __name__ == "__main__":
    main()
