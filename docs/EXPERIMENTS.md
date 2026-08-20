# 实验清单

规则：每个实验一个分支 `feat/<name>`；实验前后各跑一次基线（docs/BASELINE.md）；
结论（数据 + 分析）写回本文件再合入。

## 候选 feature（按收益/学习价值排序，待细化）

- [ ] greedy / top-k / top-p 采样：解除 `temperature > 1e-10` 限制（当前 Sampler 只做
      Gumbel-max，见 `nanovllm/layers/sampler.py` + `sampling_params.py`）
- [ ] 前缀缓存感知调度：`BlockManager` 已有 xxhash 块哈希，可做调度侧优先分配命中序列
- [ ] chunked prefill 扩展到所有序列：目前只对第一个被调度序列生效（scheduler.py）
- [ ] 抢占策略改进：当前直接释放全部块回 waiting 队首，可做基于 KV cache 块数的
      swap/evict
- [ ] decode 批大小自适应 / CUDA graph 桶细化（model_runner.py 的 graph_bs）
- [ ] 输出流式 / 增量 token 回调：`LLM.generate` 是黑盒，可暴露逐 token 回调
- [ ] 与 vLLM 对照的可复现 harness（独立环境装 vLLM，同负载跑 A/C 矩阵）

## 记录格式

```text
### [日期] feat/<name>
- 改动：...
- 基线：xxx tok/s
- 实验：xxx tok/s（±x%）
- 结论：...
```
