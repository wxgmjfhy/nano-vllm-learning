#!/usr/bin/env bash
# 下载模型到本地目录（不入 git）。用法: bash download_model.sh [HF_ID] [目标目录]
set -euo pipefail

MODEL="${1:-Qwen/Qwen3-0.6B}"
DIR="${2:-/root/autodl-tmp/huggingface/Qwen3-0.6B}"

echo "==> 下载 $MODEL -> $DIR（hf-mirror，禁用 Xet）"
mkdir -p "$(dirname "$DIR")"
HF_ENDPOINT=https://hf-mirror.com HF_HUB_DISABLE_XET=1 \
  huggingface-cli download "$MODEL" --local-dir "$DIR"
echo "完成。若 nano-vllm 默认路径是 ~/huggingface/Qwen3-0.6B，可建软链："
echo "  ln -sfn $DIR /root/huggingface"
