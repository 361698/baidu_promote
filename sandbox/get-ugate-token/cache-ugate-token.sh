#!/usr/bin/env bash
set -euo pipefail

# 沙箱版 cache-ugate-token.sh：把 UGate JWT 同时写两份——
#   1. $SKILL_DIR/private/.eac_ugate_token_<uuap>   持久仓库（跟随 skill，跨会话存活）
#   2. $HOME/.config/uuap/.eac_ugate_token_<uuap>   CLI 实际读取位置（本会话立即可用）
# 这样下个新会话即使 $HOME 变了，也能用 ensure-token.sh 从 private/ hydrate 回来。
# 单一鉴权链路：只缓存 UGate token，不涉及数字员工 / OpenAPI。
# private/ 必须 gitignore，绝不提交、不复述完整 token。

usage() {
  cat <<'EOF'
Usage:
  scripts/cache-ugate-token.sh <uuap>            # 从剪贴板读取（macOS pbpaste）
  scripts/cache-ugate-token.sh <uuap> --stdin    # 从 stdin 读取（终端/沙箱）
说明：脚本只读取一次，不等待剪贴板变化，也不会打印 token 本身。
同时写入 $SKILL_DIR/private 持久仓库和 $HOME/.config/uuap 本会话缓存。
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ -z "${1:-}" ]; then
  usage; exit 0
fi

UUAP="$1"; shift || true
READ_STDIN=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --stdin) READ_STDIN=1; shift ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
FNAME=".eac_ugate_token_${UUAP}"
PRIV_DIR="$SKILL_DIR/private"
HOME_DIR="$HOME/.config/uuap"

command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 1; }
if [ "$READ_STDIN" -eq 0 ] && ! command -v pbpaste >/dev/null 2>&1; then
  echo "pbpaste 不可用，请改用 --stdin" >&2; exit 1
fi

extract_token() {
  python3 -c '
import re, sys
text = sys.stdin.read().strip()
if not text:
    sys.exit(1)
patterns = [
    r"ugate\s+token\s*[:：]\s*(eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)",
    r"\b(eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)\b",
]
for p in patterns:
    m = re.search(p, text, flags=re.IGNORECASE | re.DOTALL)
    if m:
        print(m.group(1).strip()); sys.exit(0)
sys.exit(1)
'
}

if [ "$READ_STDIN" -eq 1 ]; then
  TOKEN="$(cat | extract_token 2>/dev/null || true)"
else
  TOKEN="$(pbpaste 2>/dev/null | extract_token 2>/dev/null || true)"
fi

if [ -z "${TOKEN:-}" ]; then
  echo "没有识别到 UGate JWT token。请确认用户已复制页面里的 eyJ... token 后再运行。" >&2
  exit 1
fi

write_one() {
  local dir="$1"
  mkdir -p "$dir"; chmod 700 "$dir" 2>/dev/null || true
  python3 - "$TOKEN" "$dir/$FNAME" <<'PY'
import json, sys
from pathlib import Path
token = sys.argv[1].strip()
path = Path(sys.argv[2])
path.write_text(json.dumps({"token": token, "permanent": True}, ensure_ascii=False), encoding="utf-8")
path.chmod(0o600)
PY
}

write_one "$PRIV_DIR"
write_one "$HOME_DIR"
echo "OK 已写入持久仓库 $PRIV_DIR/$FNAME 与本会话缓存 $HOME_DIR/$FNAME"
