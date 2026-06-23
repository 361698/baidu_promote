#!/usr/bin/env bash
set -euo pipefail

# 运行前自检：确认工具文件齐全、可执行，UGate 缓存就绪。
# 单一鉴权链路：只看本机 UGate 缓存，不涉及数字员工 / OpenAPI。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
missing=0

check_path() {
  local path="$1"
  if [ -e "$path" ]; then
    echo "OK $path"
  else
    echo "MISSING $path"
    missing=1
  fi
}

check_exec() {
  local path="$1"
  if [ -x "$path" ]; then
    echo "OK executable $path"
  else
    echo "MISSING_OR_NOT_EXECUTABLE $path"
    missing=1
  fi
}

check_path "$SKILL_DIR/SKILL.md"
check_exec "$SKILL_DIR/bin/ku"
check_exec "$SKILL_DIR/scripts/cache-ugate-token.sh"

uuap="${SANDBOX_USERNAME:-${BAIDU_CC_USERNAME:-}}"
if [ -n "$uuap" ] && [ -f "$HOME/.config/uuap/.eac_ugate_token_${uuap}" ]; then
  echo "OK UGate cache for $uuap"
elif [ -n "$uuap" ]; then
  echo "WARN UGate cache missing for $uuap，先运行 scripts/cache-ugate-token.sh $uuap"
else
  echo "WARN 请先 export SANDBOX_USERNAME=<uuap> 再做认证相关命令"
fi

exit "$missing"
