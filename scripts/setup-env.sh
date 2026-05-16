#!/bin/bash
# Run inside pod to set up user conda/pip environment.
# Usage: bash /sciclone/home/cwang33/k8s_archive/scripts/setup-env.sh

set -euo pipefail

export HOME="${HOME:-/sciclone/home/cwang33}"
export PATH="$HOME/anaconda3/bin:$HOME/.local/bin:$PATH"

echo "=== Activating conda base ==="
eval "$(conda shell.bash hook)"
conda activate base

echo "=== Installing pip packages (user) ==="
pip install --user --no-cache-dir \
    jupyter notebook ipykernel \
    pandas numpy matplotlib scikit-learn \
    tqdm transformers datasets accelerate \
    debugpy 2>/dev/null || true

echo "=== Done. Environment ready. ==="
