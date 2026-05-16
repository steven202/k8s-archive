FROM pytorch/pytorch:2.6.0-cuda12.6-cudnn9-devel

# System packages (apt)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git vim htop tmux jq \
    build-essential net-tools iputils-ping \
    openssh-client ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# code-server (pre-downloaded binary, no root needed at runtime)
ARG CS_VER=4.99.3
RUN curl -fsSL "https://github.com/coder/code-server/releases/download/v${CS_VER}/code-server-${CS_VER}-linux-amd64.tar.gz" \
    | tar -xz -C /usr/local/lib && \
    ln -s /usr/local/lib/code-server-${CS_VER}-linux-amd64/bin/code-server /usr/local/bin/code-server

# cloudflared (pre-downloaded binary)
ARG CF_VER=2026.5.0
RUN curl -fsSL -o /usr/local/bin/cloudflared \
    "https://github.com/cloudflare/cloudflared/releases/download/${CF_VER}/cloudflared-linux-amd64" && \
    chmod +x /usr/local/bin/cloudflared

# Python / pip packages
RUN pip install --no-cache-dir \
    jupyter notebook ipykernel \
    pandas numpy matplotlib scikit-learn \
    tqdm transformers datasets accelerate \
    debugpy

# Entrypoint default (can be overridden by YAML command)
CMD ["/bin/bash"]
