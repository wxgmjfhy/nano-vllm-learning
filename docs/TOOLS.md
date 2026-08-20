# 开发工具（codex / grok）迁移说明

记录日期：2026-08-20。机器为 AutoDL Linux x86_64。

> 2026-08-20 策略更新：本机已改为**系统盘 + 保存镜像**迁移（工具本就装在系统盘，随镜像走），
> 下方 tar 备份与重装方案保留为"跨平台/离开 AutoDL"时的兜底。

## 现状

| 工具 | 版本 | 安装位置 | 配置/数据 |
|---|---|---|---|
| codex（OpenAI CLI） | @openai/codex 0.148.0 | nvm node v22.23.2 全局 npm 包（/root/.nvm/.../lib/node_modules/@openai/codex），核心二进制为静态链接 ELF | /root/.codex（config.toml、skills、sessions、sqlite 日志/状态） |
| grok（xAI CLI） | @xai-official/grok 1.0.5 | 同上（npm 全局包）；另有 /root/.grok/bin/grok-1.0.5 静态二进制 | /root/.grok（含登录凭据） |
| node/npm | v22.23.2（nvm） | /root/.nvm/versions/node/v22.23.2 | - |

## 三种迁移方式（按推荐度）

### 1. AutoDL 保存自定义镜像（仅限 AutoDL 内迁移）
codex/grok 都在系统盘，保存自定义镜像后新实例从镜像创建即全量还原。最简单，
但绑定 AutoDL 平台，且镜像保存/存储有费用。

### 2. tar 打包带走（跨 Linux x86_64 机器）
```bash
# 备份（本仓库脚本）
bash scripts/migrate_tools_backup.sh          # 产物: /root/backup/tools-backup-*.tar.gz
# 新机器恢复
bash scripts/migrate_tools_restore.sh /path/to/tools-backup-*.tar.gz
```
备份约 600-900MB，含 node 运行时与登录凭据。二进制为静态链接，同架构 Linux 基本即拷即用。

### 3. 重装 + 迁移配置（最干净，可跨架构）
```bash
# 新机器先装 node（推荐 nvm 装 v22.23.2）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.x/install.sh | bash
nvm install 22.23.2
# 国内建议先切 npm 镜像
npm config set registry https://registry.npmmirror.com
npm i -g @openai/codex@0.148.0 @xai-official/grok@1.0.5
# 再从备份/旧机器拷贝配置目录（含凭据，私密传输）
scp -r root@旧机器:/root/.codex /root/.codex
scp -r root@旧机器:/root/.grok  /root/.grok
```

## 安全提醒

- `~/.codex`、`~/.grok` 内含登录 token/API key，**不要**提交到公开仓库。
- GitHub PAT 曾在本会话中以明文出现，建议之后重新生成。
- `~/.npm`（300MB）只是缓存，无需备份。
