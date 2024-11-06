# Base image with CUDA 12.2
FROM nvidia/cuda:12.2.2-base-ubuntu22.04

# Install pip and other dependencies
RUN apt-get update -y && apt-get install -y \
    python3-pip \
    python3-dev \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Define environment variables for UID and GID
ENV PUID=${PUID:-1000}
ENV PGID=${PGID:-1000}

# Create a group and user with the specified UID and GID
RUN groupadd -g "${PGID}" appuser && \
    useradd -m -s /bin/sh -u "${PUID}" -g "${PGID}" appuser

# Set working directory
WORKDIR /app

# Clone sd-scripts repository into /app/fluxgym/sd-scripts and install dependencies
RUN git clone -b sd3 https://github.com/kohya-ss/sd-scripts /app/fluxgym/sd-scripts && \
    cd /app/fluxgym/sd-scripts && \
    pip3 install --no-cache-dir -r requirements.txt

# Install main application dependencies
COPY requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Install PyTorch Nightly for CUDA 12.1
RUN pip3 install torch torchvision torchaudio --pre --index-url https://download.pytorch.org/whl/cu121

# Copy fluxgym application code
COPY . ./fluxgym

# Ensure the 'outputs' and 'models' directories exist
RUN mkdir -p /app/fluxgym/outputs /app/fluxgym/models

# Change ownership of application directories to non-root user
RUN chown -R appuser:appuser /app/fluxgym

# Set permissions to allow appuser to write to all directories
RUN chmod -R 755 /app/fluxgym

# Set environment variable for Gradio
ENV GRADIO_SERVER_NAME="0.0.0.0"

# Expose the application port
EXPOSE 7860

# Switch to non-root user
USER appuser

# Set working directory to fluxgym
WORKDIR /app/fluxgym

# Run the Fluxgym application
CMD ["python3", "app.py"]
