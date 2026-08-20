#!/usr/bin/env bash
# 新机器恢复 codex/grok（Linux x86_64）。
# 用法: bash migrate_tools_restore.sh /path/to/tools-backup-*.tar.gz
set -euo pipefail

TARBALL="${1:?用法: bash migrate_tools_restore.sh <备份tar.gz>}"
test -f "$TARBALL"

echo "==> 解包到 /root"
tar xzf "$TARBALL" -C /root

NODE_BIN="/root/.nvm/versions/node/v22.23.2/bin"
CODEX_PATH="/root/.nvm/versions/node/v22.23.2/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path"

echo "==> 写入 shell rc（PATH）"
for RC in /root/.bashrc /root/.zshrc; do
  if [ -f "$RC" ] && ! grep -q "$CODEX_PATH" "$RC" 2>/dev/null; then
    printf 'export PATH="%s:$PATH"\nexport PATH="%s:$PATH"\n' "$NODE_BIN" "$CODEX_PATH" >> "$RC"
  fi
done

echo "==> 验证"
"$NODE_BIN/codex" --version
"$NODE_BIN/grok" --version || /root/.grok/bin/grok-1.0.5 --version
echo "恢复完成。重新打开终端即可直接使用 codex / grok"
