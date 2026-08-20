# Baseline 基准

所有实验的对照基准。跑新的 feature 前先更新这里的"最新基线"。

## 环境指纹（记录，便于跨机器对比）

- 机器/GPU：AutoDL RTX 3090 24GB（本机首测）；README 官方：RTX 4070 Laptop 8GB
- 软件：torch 2.5.1+cu124 / flash-attn 2.7.4.post1（源码编译 sm86）/ transformers 5.15.0
- 模型：Qwen/Qwen3-0.6B（bf16，28 层，本地路径 /root/autodl-tmp/huggingface/Qwen3-0.6B）
- 记录日期：2026-08-19

## 最新基线（bench.py 原样）

| 引擎 | 序列数 | 输入/输出长度 | 总 tokens | 耗时 | 吞吐 tok/s | 峰值显存 |
|---|---|---|---|---|---|---|
| nano-vLLM (3090) | 256 | 随机 100-1024 | 133,966 | 28.84s | **4,645** | 22.3GB（预分配 KV cache） |
| nano-vLLM (4070, README) | 256 | 随机 100-1024 | 133,966 | 93.41s | 1,434 | - |
| vLLM (4070, README) | 256 | 随机 100-1024 | 133,966 | 98.37s | 1,362 | - |

## 待测矩阵（vLLM 对照待装独立环境后补）

| 维度 | 取值 | 目的 |
|---|---|---|
| A. 合成基准 | 同 bench.py | 引擎对照、README 对齐 |
| B. 真实文本 | 50-100 条 ShareGPT/alpaca 风格 prompt + chat template | 真实场景 + 输出质量 |
| C. 序列数扫描 | 1/16/64/128/256/512 | decode 吞吐扩展性 |
| D. 长度分布 | 短(64-256)/中(256-1024)/长(1024-4096)/skewed | 调度与抢占行为 |
| E. 前缀缓存 | 100 条共享 512-token 前缀，冷/热各一次 | 前缀缓存收益 |
| F. 长上下文 | max_model_len=16384，prompt 8k-16k | chunked prefill |

## 指标口径

- 吞吐 = 总输出 tokens / 总耗时；prefill/decode 分开统计（harness 驱动 `llm.step()` 逐帧记录）
- 同 seed 重复 3 次取中位数；首次调用（含 CUDA graph capture）不计入
- 显存用 `torch.cuda.max_memory_allocated` 区分"真实占用"与"预分配 KV cache"
- 正确性：nano-vLLM vs vLLM vs HF transformers 采样输出对比（nano 不支持 greedy，不能逐字比对）
