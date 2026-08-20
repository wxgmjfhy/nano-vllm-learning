#!/usr/bin/env bash
# 新机器环境恢复脚本。前提：AutoDL GPU 镜像（已含 torch 2.5.1+cu124）。
# 其他 GPU 型号请修改 FLASH_ATTN_CUDA_ARCHS / TORCH_CUDA_ARCH_LIST（见 AGENTS.md 踩坑记录）。
set -euo pipefail

echo "==> 1/4 检查 Python 与 CUDA"
python -c "import sys; assert sys.version_info >= (3,10), '需要 Python >= 3.10'"
nvcc --version | tail -1

echo "==> 2/4 安装核心依赖"
pip install --timeout 60 transformers xxhash safetensors huggingface-hub

echo "==> 3/4 源码编译 flash-attn（PyPI 无此环境的可用 wheel，勿直接 pip install flash-attn）"
FLASH_ATTENTION_FORCE_BUILD=TRUE \
FLASH_ATTN_CUDA_ARCHS=86 \
TORCH_CUDA_ARCH_LIST=8.6 \
MAX_JOBS=20 \
pip install --no-cache-dir --no-build-isolation flash-attn==2.7.4.post1

echo "==> 4/4 验证"
python - <<'PY'
import torch, flash_attn, transformers
print("torch       :", torch.__version__)
print("flash_attn  :", flash_attn.__version__)
print("transformers:", transformers.__version__)
print("cuda        :", torch.cuda.is_available())
PY
echo "环境就绪（GPU 相关功能需在带 GPU 模式下验证）"
