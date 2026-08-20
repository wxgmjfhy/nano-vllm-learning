# nano-vllm learning repo

学习 `https://github.com/GeeeekExplorer/nano-vllm`（从零实现的轻量 vLLM）的项目仓库。
目标是：掌握核心 feature，并在此仓库上做 feature 优化实验。本仓库承载所有**任务上下文**，
换机器时 clone 下来即可快速恢复。

## 仓库内容

- `AGENTS.md` — 环境信息、踩坑记录、架构速查、学习顺序（任务的"核心上下文"，换机器第一件事）
- `scripts/` — 新机器一键恢复脚本（装依赖 / 下模型 / 冒烟测试）
- `scripts/migrate_tools_*.sh` + `docs/TOOLS.md` — codex/grok 工具迁移
- `docs/BASELINE.md` — 基线指标与测试矩阵（每个实验的对照基准）
- `docs/EXPERIMENTS.md` — 实验清单与分支规范

## 新机器上手（迁移指南）

```bash
# 1. 克隆本仓库（AutoDL 网络对 GitHub 不稳，先固定 HTTP/1.1）
git config --global http.version HTTP/1.1
git clone https://github.com/<your-account>/nano-vllm-learning.git
cd nano-vllm-learning

# 2. 恢复环境（需 GPU 镜像，如 RTX 3090）
bash scripts/setup_env.sh

# 3. 下载模型（走 hf-mirror，模型不存 git）
bash scripts/download_model.sh

# 4. 冒烟测试 + 基线
bash scripts/smoke_test.sh
```

> 若走 AutoDL **保存镜像**迁移（推荐）：系统盘（含 conda/flash-attn、工具、模型、源码）
> 已随镜像恢复，无需 setup_env.sh；此时只需 clone 本仓库把 AGENTS.md 复制到 agent 工作目录
> （数据盘默认工作目录）即可恢复全部上下文。

## 日常流程

- 每次实验结束：`git add -A && git commit -m "..." && git push`（先 commit 再 push 到 GitHub，
  实例被释放也不丢）。
- 每个新 feature 开独立分支 `feat/<name>`，结果写进 `docs/EXPERIMENTS.md` 并提交。
- 模型权重/编译产物/日志一律不入库（见 `.gitignore`）。
