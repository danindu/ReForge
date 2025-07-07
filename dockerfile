# Use a standard Ubuntu base image
FROM ubuntu:22.04

# Set non-interactive mode for package installations
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git python3 python3-pip build-essential clang llvm cmake curl

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Set the working directory inside the container
WORKDIR /app

# Copy all your project files into the container
# The .dockerignore file will prevent secrets like .env from being copied.
COPY . .

# Make setup scripts executable and run them
# This installs system dependencies and AFL++
RUN chmod +x *.sh
RUN ./install_afl.sh

# Install all Python dependencies
RUN pip3 install -r requirements.txt

# Create startup script that sets up Ollama model on first run
RUN echo '#!/bin/bash\n\
echo "=== Starting Ollama Setup ==="\n\
ollama serve &\n\
OLLAMA_PID=$!\n\
echo "Waiting for Ollama to start..."\n\
sleep 10\n\
\n\
# Check if custom model exists\n\
if ! ollama list | grep -q "reforge-gpt"; then\n\
    echo "Setting up custom reforge-GPT model..."\n\
    ollama pull llama2:7b-chat-q4_0\n\
    ollama create reforge-gpt -f ./modelfile\n\
    echo "Custom model setup complete!"\n\
else\n\
    echo "Custom model already exists"\n\
fi\n\
\n\
echo "=== Ollama Ready ==="\n\
echo "Available models:"\n\
ollama list\n\
echo ""\n\
echo "Ready to run experiments!"\n\
exec "$@"\n' > /app/start_with_ollama.sh && \
chmod +x /app/start_with_ollama.sh

# Expose Ollama port
EXPOSE 11434

# Set the default command to run when the container starts
CMD ["/app/start_with_ollama.sh", "/bin/bash"]