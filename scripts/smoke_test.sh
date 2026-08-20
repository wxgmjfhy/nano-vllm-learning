#!/usr/bin/env bash
# 冒烟测试：跑通 nano-vllm 的 example.py。需要 GPU 模式。
set -euo pipefail

NANO_DIR="${NANO_VLLM_DIR:-/root/nano-vllm}"

if [ ! -d "$NANO_DIR" ]; then
  echo "未找到 nano-vllm 源码目录 $NANO_DIR，请先克隆上游或设置 NANO_VLLM_DIR"
  exit 1
fi

cd "$NANO_DIR"
python example.py
echo "smoke test OK"
