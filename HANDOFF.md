# HANDOFF — 会话交接记录

更新：2026-08-20（环境已通过 AutoDL 镜像迁移到新机器）

## 一句话现状

nano-vllm 学习/优化项目：环境、代码、模型、工具已随系统盘迁移到新机器；
新机器**尚未做迁移验证**；下一步 = 验证环境 → 写基准 harness → 跑测试矩阵。

## 项目布局（新机器）

- 源码（tarball 副本，无 .git）：`/root/nano-vllm`
- 学习仓库（git，与 GitHub 同步）：`/root/nano-vllm-learning`（本文件所在）
- 模型权重：`/root/huggingface/Qwen3-0.6B`
- 数据盘 `/root/autodl-tmp`：仅 `.autodl` + `AGENTS.md`（工作区副本）
- 迁移策略：系统盘 + 保存镜像；GitHub 兜底

## 已完成（旧机器 2026-08-19/20）

- 依赖：torch 2.5.1+cu124 / flash-attn 2.7.4.post1（源码编译，sm86）/ transformers 5.15.0 / xxhash / safetensors / huggingface-hub
- `example.py` 跑通：两条 prompt 正常输出（含 think 块）
- baseline：`bench.py` 256 序列 → 133,966 tokens / 28.84s = **4,645 tok/s**（3090；显存峰值 22.3GB 为预分配 KV cache）
- 工具：nvm node v22.23.2 + codex 0.148.0 / grok 1.0.5 / claude-code / tmux，登录态随镜像迁移
- 网络修复：`git config --global http.version HTTP/1.1`；github.com IPv6 不通 → `/etc/hosts` 固定 IPv4（新机器可能需重做）
- 仓库已推送至 GitHub：最新 commit `d19bc12`

## 待办（按优先级）

1. [ ] 新机器迁移验证（见下方"验证命令"）
2. [ ] 把 `AGENTS.md` 复制到工作目录 `/root/autodl-tmp/AGENTS.md`，供新会话自动加载
3. [ ] 编写 `bench_harness.py`：驱动 `llm.step()`，输出 prefill/decode 分解吞吐、TTFT、真实显存峰值，落 CSV/JSON
4. [ ] 跑 baseline 矩阵 A/B/C（合成基准 / 真实文本 / 序列数 1-512 扫描）；再补 E（前缀缓存冷热）、F（长上下文 chunked prefill）
5. [ ] vLLM 对照：**独立 conda 环境**安装（vllm 0.8.5 强制 torch 2.6，勿装进当前环境），同负载对比
6. [ ] 正确性对照：HF transformers 采样输出 vs nano-vLLM
7. [ ] feature 实验（见 `docs/EXPERIMENTS.md`）：greedy/top-k/top-p 采样、chunked prefill 全序列、抢占改进、decode 批/CUDA graph 桶优化等

## 验证命令（新机器）

```bash
nvidia-smi    # GPU 是否可用、型号
python -c "import torch, flash_attn, transformers; print(torch.__version__, flash_attn.__version__, transformers.__version__)"
ls /root/huggingface/Qwen3-0.6B/config.json
cd /root/nano-vllm && python example.py     # 冒烟，需 GPU
codex --version; grok --version; tmux -V
git -C /root/nano-vllm-learning log --oneline -3
```

## 注意事项

- GitHub push 需要 PAT（不在仓库内）；建议新机器执行一次 `git config --global credential.helper store`。
- flash-attn 按 sm86（3090）编译：新机器若 GPU 架构不同（4090=sm89 / A100=sm80 / H100=sm90），需按 `AGENTS.md` 踩坑记录重编：
  `FLASH_ATTENTION_FORCE_BUILD=TRUE FLASH_ATTN_CUDA_ARCHS=<arch> TORCH_CUDA_ARCH_LIST=<arch> MAX_JOBS=20 pip install --no-cache-dir --no-build-isolation flash-attn==2.7.4.post1`
- 凭据（`~/.codex`、`~/.grok` 登录态）已随镜像迁移，勿写入仓库/分享。
- 长任务用 tmux 独立会话，exec 会话会回收子进程。

## 新会话接手姿势

```bash
cd /root/nano-vllm-learning   # 或先把 AGENTS.md 复制到工作目录
```

开场白示例："阅读 AGENTS.md、README、HANDOFF.md，先做新机器迁移验证，再按待办推进。"
