#!/bin/bash
# Install ML environment on NFS home (run once inside pod, persists across restarts).
# Usage: bash /sciclone/home/cwang33/k8s_archive/scripts/install-ml-env.sh

set -euo pipefail
export HOME="${HOME:-/sciclone/home/cwang33}"

echo "=== Installing ML packages (this may take 10-15 min) ==="

pip install --user --no-cache-dir \
    "transformers==4.57.6" \
    "accelerate==1.12.0" \
    "wandb" \
    "datasets==4.5.0" \
    "gradio==6.4.0" \
    "pandas==2.3.3" \
    "scikit-learn==1.8.0" \
    "evaluate==0.4.6" \
    "peft==0.18.1" \
    "safetensors==0.7.0" \
    "sentencepiece==0.2.1" \
    "protobuf==6.33.4" \
    "scipy==1.17.0" \
    "rich==14.2.0" \
    "networkx==3.5" \
    "ninja==1.13.0" \
    "bitsandbytes==0.49.1"

echo "=== Done. Packages installed to ~/.local ==="
python -c "import transformers, torch; print(f'transformers {transformers.__version__}, torch {torch.__version__}, CUDA {torch.cuda.is_available()}')"
