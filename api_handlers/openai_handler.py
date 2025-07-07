#!/usr/bin/env python3
"""OpenAI API Handler for exploit generation (patched)."""
import os, sys
from openai import OpenAI
from colorama import Fore, Style
from dotenv import load_dotenv

class OpenAIHandler:
    def __init__(self, api_key: str = None):
        load_dotenv()
        self.api_key = api_key or os.getenv("AI_API_KEY")
        if not self.api_key:
            raise ValueError("AI_API_KEY missing")
        self.client = OpenAI(api_key=self.api_key)
        self.model = "gpt-4o"

    def generate_exploit(self, crash_file_path: str, binary_path: str):
        """Reads crash file, sends prompt, prints Python exploit"""
        try:
            with open(crash_file_path, "rb") as f:
                crash_data = f.read()
            crash_preview = crash_data[:64].hex()
        except Exception as e:
            print(f"{Fore.RED}Error reading crash: {e}{Style.RESET_ALL}", file=sys.stderr)
            sys.exit(1)

        prompt = f"""You are an expert exploit developer. I am passing you:
- A crash input file (from AFL++ fuzzing)
- The associated binary file (un-instrumented ELF)
- Both provided via full file paths

Your task is:
1. Statically analyze the binary (no debuggers).
2. Parse the crash input to understand why it crashes.
3. Generate a standalone **Python** exploit script that:
   • Writes the exact crash bytes to a temp file  
   • Executes the binary with that file as argument  
   • Reproduces the crash/hang exactly  
    ^`  Add success or failure print statements, print payload used, print the segment code(if applicble)  
   • Cleans up the temp file  

Constraints:
- No GDB, lldb, or dynamic instrumentation
- Only standard Python + subprocess (no pwntools)
- Assume the binary reads the input **as a file argument**

INPUTS  
Binary path: {binary_path}  
Crash file path: {crash_file_path}

Crash preview (hex, first 64 bytes): {crash_preview}

Respond **only** with the full Python code of the exploit script. """

        response = self.client.chat.completions.create(
            model=self.model,
            temperature=0,
            messages=[
                {"role": "system", "content": "You are a helpful assistant that outputs only Python code blocks."},
                {"role": "user", "content": prompt}
            ]
        )
        code = self._extract_python_code(response.choices[0].message.content)
        if not code:
            print(f"{Fore.RED}No Python code returned.{Style.RESET_ALL}", file=sys.stderr)
            sys.exit(1)
        print(code)

    def _extract_python_code(self, text: str) -> str:
        if "```python" in text:
            start = text.find("```python") + len("```python\n")
            end = text.find("```", start)
            return text[start:end].strip()
        return text.strip()

def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <crash_file> <binary_path>", file=sys.stderr)
        sys.exit(1)
    handler = OpenAIHandler()
    handler.generate_exploit(sys.argv[1], sys.argv[2])

if __name__ == "__main__":
    main()
