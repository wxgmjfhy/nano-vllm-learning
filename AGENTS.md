# AGENTS.md — nano-vllm 学习项目

最后核对：2026-08-19（仓库 main 分支，commit bb823b3，v0.2.0，MIT，作者 Xingkai Yu，约 15k stars）

## 1. 当前机器环境（AutoDL）

- GPU：NVIDIA GeForce RTX 3090（24 GB，驱动 595.71.05，驱动级 CUDA 13.2）
- CPU 20 核，内存 90 GB
- Python 3.12.3，PyTorch 2.5.1+cu124，triton 3.1.0

### 磁盘与迁移策略（2026-08-20 更新）

- **工作数据全部放系统盘**：项目源码 `/root/nano-vllm`、学习仓库 `/root/nano-vllm-learning`、
  模型权重 `/root/huggingface/Qwen3-0.6B`。
- 数据盘 `/root/autodl-tmp` 不再存放项目数据，只保留 AutoDL 系统文件（`.autodl`）与
  当前工作区的 `AGENTS.md` 副本。
- 迁移方式：**AutoDL 保存自定义镜像**（系统盘随镜像走，数据盘不随镜像走）。新机器从镜像
  创建后：环境/工具/登录态/模型/源码原样恢复；若换 GPU 架构需按"踩坑记录"重编 flash-attn。
- 系统盘 30 GB：conda(~6.5G) + 工具(~1.5G) + 模型(1.5G) + 源码，余量充足，但别把大缓存/日志堆进去。
- GitHub 兜底：`https://github.com/wxgmjfhy/nano-vllm-learning`（AGENTS.md/脚本/实验记录），
  实例释放或镜像损坏时不丢上下文。新机器上若 agent 工作目录在数据盘，先把
  `/root/nano-vllm-learning/AGENTS.md` 复制到工作目录再继续。

### 依赖现状（2026-08-19 已全部装好）

- 已装：torch 2.5.1+cu124、triton 3.1.0、transformers 5.15.0、flash-attn 2.7.4.post1（**源码编译**，见下方踩坑）、xxhash、safetensors、huggingface-hub 1.28.0
- 未装：vllm（如需对比基准再装）

### 踩坑记录（重要）

- **flash-attn 装法**：PyPI/阿里云镜像只有 sdist，且其 setup.py 在 bdist_wheel 时会先尝试从 GitHub Release 下载预编译 wheel（无超时，国内网络会卡死）。正确做法是源码编译：
  ```bash
  FLASH_ATTENTION_FORCE_BUILD=TRUE FLASH_ATTN_CUDA_ARCHS=86 \
  TORCH_CUDA_ARCH_LIST=8.6 MAX_JOBS=20 \
  pip install --no-cache-dir --no-build-isolation flash-attn==2.7.4.post1
  ```
  只编 sm86（3090）约 20 分钟；默认会编 sm80+sm90，时间翻倍。不要用 HF 上第三方 cp312 wheel（如 nopesadly/flash-attn-wheels 的 2.8.3），是按新版 torch 编的，torch 2.5.1 下 `undefined symbol` 直接挂。
- **下载模型走 hf-mirror**，并禁 Xet（新版 huggingface-hub 默认 Xet 后端，镜像 401）：
  ```bash
  HF_ENDPOINT=https://hf-mirror.com HF_HUB_DISABLE_XET=1 \
    huggingface-cli download Qwen/Qwen3-0.6B \
    --local-dir /root/huggingface/Qwen3-0.6B
  ```
- **长任务会断**：exec 命令返回时会清掉其后台子进程；长时间挂着的会话也会被回收。长任务请用 `tmux new-session -d -s <name> '<cmd> > log 2>&1'` 跑，再轮询日志。
- GitHub 直连慢/断，下载大文件可试 gh-proxy.com（单连接约 0.5MB/s，且中途会断，配合 `curl -C -` 续传）；优先找 hf-mirror 上的替代资源。

### 网络坑：GitHub 克隆失败

`git clone https://github.com/...` 会报 `HTTP/2 stream 1 was not closed cleanly`。解决办法：

- 加 `-c http.version=HTTP/1.1` 重试克隆；或
- 直接下载 tarball：`curl -L --http1.1 -o /tmp/x.tar.gz https://codeload.github.com/<owner>/<repo>/tar.gz/refs/heads/main`
- GitHub **推送/访问超时**（connect 443 卡 ~130s）多为 IPv6 路由不通：`curl -4 https://github.com`
  能通即可 `printf '20.205.243.166 github.com\n' >> /etc/hosts` 固定 IPv4 后重试（AutoDL 新机器同样会遇到）。

## 2. 项目概况

仓库：`https://github.com/GeeeekExplorer/nano-vllm`

本地副本：`/root/nano-vllm`（由 codeload tarball 解压，**无 .git**，如需更新用上面 codeload 方式重下）

nano-vllm 是一个从零实现的轻量级 vLLM：离线批量推理，API 仿照 vLLM（`LLM` / `SamplingParams` / `generate`），全部代码约 1,450 行 Python。官方基准（RTX 4070 Laptop 8GB、Qwen3-0.6B、256 条序列）：Nano-vLLM 1434 tok/s，vLLM 1362 tok/s。

特性：Paged KV Cache、Prefix Caching（xxhash 块哈希）、Chunked Prefill、Continuous Batching、CUDA Graph（decode）、Tensor Parallelism（NCCL + 共享内存 IPC）、torch.compile 优化算子。

## 3. 代码结构

```text
nanovllm/
├── llm.py                  # LLM(LLMEngine)，入口
├── config.py               # Config：max_num_seqs=512、max_num_batched_tokens=16384、
│                           #   max_model_len=4096、gpu_memory_utilization=0.9、
│                           #   tensor_parallel_size=1、enforce_eager=False、
│                           #   kvcache_block_size=256（须为 256 倍数）
├── sampling_params.py      # SamplingParams：temperature/max_tokens/ignore_eos，
│                           #   temperature 必须 > 1e-10（不允许 greedy）
├── engine/
│   ├── llm_engine.py       # 主循环：add_request / step / generate；TP>1 时 spawn 子进程
│   ├── scheduler.py        # prefill→decode 两阶段调度；chunked prefill；抢占（deallocate 后回 waiting）
│   ├── sequence.py         # Sequence 状态机（WAITING/RUNNING/FINISHED）；__getstate__ 只传 last_token
│   ├── block_manager.py    # Paged KV cache 块分配/引用计数/xxhash 前缀缓存
│   └── model_runner.py     # 权重加载、KV cache 分配、prefill/decode 数据组装、CUDA graph
├── models/qwen3.py         # 目前唯一支持的模型架构 Qwen3ForCausalLM
├── layers/                 # attention（flash-attn + triton 写 KV）、linear（TP 分片）、
│                           #   embed_head、layernorm、rotary_embedding、activation、sampler
└── utils/                  # context（全局推理上下文）、loader（safetensors 权重加载）
```

## 4. 核心机制速查（学习重点）

1. **Paged KV Cache**：KV cache 为 `(2, layers, blocks, 256, kv_heads, head_dim)`；`Sequence.block_table` 映射逻辑块→物理块，`slot_mapping` 由 `block_id*256 + offset` 计算，triton kernel 按 slot 写入。
2. **Prefix Caching**：`BlockManager` 对每个块算 xxhash64（含前块哈希前缀），`hash_to_block_id` 命中即复用，用引用计数管理共享块。
3. **Chunked Prefill / Continuous Batching**：`scheduler.schedule()` 先尽可能填 prefill，再轮转 decode；chunked prefill 只对第一个被调度的序列生效。
4. **CUDA Graph**：decode 且 `enforce_eager=False`、bs≤512 时按 `[1,2,4,8,16,...]` 桶回放；prefill 始终 eager。
5. **Tensor Parallelism**：rank 0 在主进程，rank≥1 为 `mp.get_context("spawn")` 子进程；NCCL init 固定 `tcp://localhost:2333`；命令经 1MB `SharedMemory("nanovllm")` + Event 传递；Sequence 经 pickle 传输（decode 时只带 last_token，见 `__getstate__`）。
6. **注意力**：prefill 用 `flash_attn_varlen_func`（前缀命中时配合 block_table 从缓存读 KV），decode 用 `flash_attn_with_kvcache`。
7. **采样**：`Sampler` 用 Gumbel-max 技巧（`softmax(logits/T)` 除以指数噪声取 argmax），无 top-k/top-p。
8. **torch.compile**：RMSNorm、SiLU×Mul、Sampler 均标注 `@torch.compile`。

## 5. 运行方法

```bash
# 1. 装依赖（见上）
# 2. 下载模型（Qwen3-0.6B，约 1.2 GB，放系统盘）
HF_ENDPOINT=https://hf-mirror.com HF_HUB_DISABLE_XET=1 \
  huggingface-cli download Qwen/Qwen3-0.6B --local-dir /root/huggingface/Qwen3-0.6B
# 3. 运行（example.py / bench.py 默认路径 ~/huggingface/Qwen3-0.6B/ 即 /root/huggingface/...）
cd /root/nano-vllm
python example.py    # 两条聊天 prompt 演示
python bench.py      # 256 条随机序列压测，输出 tok/s
```

也可 `pip install -e /root/nano-vllm` 安装后任意目录使用。3090 24 GB 跑 Qwen3-0.6B 余量很大，可尝试 `max_num_seqs=512`、`tensor_parallel_size=2`（3090 单卡 TP 无收益，仅学习代码路径）。

2026-08-19 已验证：`python example.py` 跑通，两条 prompt（自我介绍 / 100 以内质数）均正常输出（含 think 块）。decode 单序列约 40-75 tok/s（enforce_eager=True 小 batch 场景）。

## 6. 已知限制 / 坑

- 仅支持 Qwen3 架构（`models/qwen3.py`），换其他模型会崩。
- 无 greedy：`temperature > 1e-10` 断言；无 top-k/top-p；无流式/HTTP server（纯离线）。
- `Config` 要求模型路径为本地目录；`max_model_len` 取配置与 HF config 的较小值。
- TP 固定端口 2333、固定 SharedMemory 名，同机多实例会冲突。
- KV cache 块数由显存预算自动算：`(total*0.9 - used - peak + current) / block_bytes`，显存紧张时 prefill 可能被 `can_allocate` 挡回。
- 抢占实现简单：直接释放该序列全部块并塞回 waiting 队首。
- 本地副本无 .git，无法直接 `git pull`；更新请走 codeload tarball 或 HTTP/1.1 克隆。

## 7. 建议学习顺序

1. `config.py` + `sampling_params.py` → 2. `sequence.py` + `block_manager.py`（缓存/分块）→ 3. `scheduler.py` → 4. `llm_engine.py`（主循环与 IPC）→ 5. `model_runner.py`（数据组装、KV 分配、CUDA graph）→ 6. `models/qwen3.py` + `layers/`（算子层）→ 7. 对照 vLLM 源码理解每处简化。
