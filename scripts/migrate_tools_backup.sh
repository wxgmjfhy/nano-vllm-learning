#!/usr/bin/env bash
# 打包系统盘上的 codex/grok 工具及其配置，便于迁移到新机器。
# 用法: bash migrate_tools_backup.sh [输出目录]   （默认 /root/backup）
#
# 注意:
# - 备份含登录凭据（~/.codex、~/.grok 内的 token/key），请用 scp 等私密渠道传输，
#   不要传到公开 GitHub / 网盘。
# - 若 codex 正在运行，sqlite 日志可能是不一致快照，仅影响历史记录，不影响功能。
set -euo pipefail

OUT="${1:-/root/backup}"
STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"

echo "==> 打包 /root/.nvm（node+npm+codex/grok 包）、/root/.codex、/root/.grok"
tar czf "$OUT/tools-backup-$STAMP.tar.gz" -C /root .nvm .codex .grok
ls -lh "$OUT/tools-backup-$STAMP.tar.gz"
echo "完成。新机器恢复: bash migrate_tools_restore.sh $OUT/tools-backup-$STAMP.tar.gz"
