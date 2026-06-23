#!/usr/bin/env bash
set -euo pipefail

# 把用户从 https://uuap.baidu.com/agent/token 复制的内容里的 UGate JWT
# 缓存到 ~/.config/uuap/.eac_ugate_token_<uuap>，供 bin/ku 读取。
# 单一鉴权链路：只缓存 UGate token，不涉及数字员工 / OpenAPI / OneAPI。

usage() {
  cat <<'EOF'
Usage:
  scripts/cache-ugate-token.sh <uuap>            # 从剪贴板读取（macOS pbpaste）
  scripts/cache-ugate-token.sh <uuap> --stdin    # 从 stdin 读取（终端/沙箱）
  scripts/cache-ugate-token.sh <uuap> --test-url "https://ku.baidu-int.com/knowledge/..."

说明：脚本只读取一次，不等待剪贴板变化，也不会打印 token 本身。
请先让用户在浏览器打开 https://uuap.baidu.com/agent/token，
若页面没显示 "ugate token: ..."，先过百度网关/SSO 再刷新，复制后再运行本脚本。
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ -z "${1:-}" ]; then
  usage
  exit 0
fi

UUAP="$1"; shift || true
TEST_URL=""
READ_STDIN=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --test-url) TEST_URL="${2:-}"; shift 2 ;;
    --stdin)    READ_STDIN=1; shift ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CACHE_DIR="$HOME/.config/uuap"
CACHE_FILE="$CACHE_DIR/.eac_ugate_token_${UUAP}"

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

mkdir -p "$CACHE_DIR"; chmod 700 "$CACHE_DIR" 2>/dev/null || true
python3 - "$TOKEN" "$CACHE_FILE" <<'PY'
import json, sys
from pathlib import Path
token = sys.argv[1].strip()
path = Path(sys.argv[2])
path.write_text(json.dumps({"token": token, "permanent": True}, ensure_ascii=False), encoding="utf-8")
path.chmod(0o600)
PY
echo "OK 已保存 UGate token 缓存：$CACHE_FILE"

if [ -n "$TEST_URL" ]; then
  export SANDBOX_USERNAME="$UUAP"
  "$SKILL_DIR/bin/ku" query-content --url "$TEST_URL" --protocol markdown --show-doc-info >/tmp/ku-doc-manage-ku-test.json
  echo "OK KU 读取测试通过，结果已保存：/tmp/ku-doc-manage-ku-test.json"
fi
