#!/usr/bin/env bash
set -euo pipefail

# ensure-token.sh —— 沙箱版每次会话拿 key 的核心。
#
# 背景：KU CLI / getUgateToken.py / enterprise-search auth.py 都写死读
#   $HOME/.config/uuap/.eac_ugate_token_<uuap>
# 沙箱里每个新会话的 $HOME 可能变化、可能与上次缓存的不在同一文件系统，
# 所以 token 经常“明明缓存过却读不到”。本脚本在每次鉴权操作前调用，
# 把 token 从持久位置 hydrate 回当前会话的 $HOME，读不到就提示重新缓存。
#
# 解析优先级（从持久 -> 易变）：
#   1. $UUAP_TOKEN_DIR/.eac_ugate_token_<uuap>      显式覆盖，最通用
#   2. $SKILL_DIR/private/.eac_ugate_token_<uuap>   跟随 skill 目录，跨会话存活
#   3. $HOME/.config/uuap/.eac_ugate_token_<uuap>   CLI 实际读取位置（最终目标）
# 命中任一持久来源就拷进 $HOME/.config/uuap/；都没有则 exit 3 让上层引导重缓存。
#
# 安全：不打印 token 内容；private/ 必须 gitignore，绝不提交。

usage() {
  cat <<'EOF'
Usage:
  ensure-token.sh <uuap>            # hydrate 当前会话的 token 缓存
  ensure-token.sh <uuap> --quiet    # 只在失败时输出
退出码：0=已就绪；3=没有任何可用来源，需要让用户重新缓存。
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ -z "${1:-}" ]; then
  usage; exit 0
fi

UUAP="$1"; shift || true
QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
FNAME=".eac_ugate_token_${UUAP}"
DEST_DIR="$HOME/.config/uuap"
DEST="$DEST_DIR/$FNAME"

say() { [ "$QUIET" -eq 1 ] || echo "$@"; }

# 已经在目标位置就不动。
if [ -s "$DEST" ]; then
  say "OK token 已在本会话 $DEST"
  exit 0
fi

# 按优先级找持久来源。
SRC=""
for cand in \
  "${UUAP_TOKEN_DIR:-}/$FNAME" \
  "$SKILL_DIR/private/$FNAME"; do
  case "$cand" in /$FNAME) continue;; esac   # UUAP_TOKEN_DIR 未设时跳过
  if [ -s "$cand" ]; then SRC="$cand"; break; fi
done

if [ -z "$SRC" ]; then
  say "MISS 没有可用的持久 token 来源（UUAP_TOKEN_DIR / $SKILL_DIR/private）。" >&2
  say "请引导用户重新缓存：bash \"$SKILL_DIR/scripts/cache-ugate-token.sh\" \"$UUAP\" [--stdin]" >&2
  exit 3
fi

mkdir -p "$DEST_DIR"; chmod 700 "$DEST_DIR" 2>/dev/null || true
cp "$SRC" "$DEST"; chmod 600 "$DEST" 2>/dev/null || true
say "OK 已从持久来源 hydrate 到本会话：$DEST"
