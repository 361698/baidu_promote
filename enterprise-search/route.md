# enterprise-search route

先设置：

```bash
export SANDBOX_USERNAME="<uuap>"
cd "$HOME/.codex/skills/enterprise-search"
```

依赖：Python3、UGate 缓存文件 `~/.config/uuap/.eac_ugate_token_<uuap>`。

## 搜索命令

知识库搜索：

```bash
SANDBOX_USERNAME="<uuap>" python3 scripts/ku_search.py --word "关键词" --page 1 --page-size 10
```

企业内搜：

```bash
SANDBOX_USERNAME="<uuap>" python3 scripts/neisou_search.py --word "关键词" --page 1
```

内搜详情：先从搜索结果拿 `resource-url`。

```bash
SANDBOX_USERNAME="<uuap>" python3 scripts/neisou_fetch.py --resource-url "<resource-url>"
```

会议搜索：

```bash
SANDBOX_USERNAME="<uuap>" python3 scripts/meeting_search.py --q "关键词"
```

周报搜索：

```bash
SANDBOX_USERNAME="<uuap>" python3 scripts/weekly_report_search.py --query "姓名或主题"
```

周报详情：先搜索拿 `uuap` 和日期。

```bash
SANDBOX_USERNAME="<uuap>" python3 scripts/weekly_report_fetch.py --uuap "<target-uuap>" --date "YYYY-MM-DD"
```

OKR 搜索：

```bash
SANDBOX_USERNAME="<uuap>" python3 scripts/okr_search.py --query "姓名或目标"
```

OKR 详情：先搜索拿 `uid` 或 `uuap`。

```bash
SANDBOX_USERNAME="<uuap>" python3 scripts/okr_fetch.py --uuap "<target-uuap>" --year "2026"
```

搜人：

```bash
SANDBOX_USERNAME="<uuap>" python3 scripts/address_search.py --type corpuser --q "姓名或邮箱前缀"
```

搜群：

```bash
SANDBOX_USERNAME="<uuap>" python3 scripts/address_search.py --type group --q "群名或成员名"
```

## 路由规则

- 需要完整详情时，先 search，再 fetch；不要直接猜 fetch 参数。
- 内搜 `resultType=0/3` 可用 `neisou_fetch.py`。
- 内搜 `resultType=16` 是知识库内容，转 `ku-doc-manage` 读取。
- 搜群只负责把自然语言线索转成 `gid`；拉群聊历史用 `knowledge-fetch`。

## 维护

如果脚本参数、时间格式、认证路径出现可复用修正，更新本文件。不要写真实群名、真实人名、真实 token。
