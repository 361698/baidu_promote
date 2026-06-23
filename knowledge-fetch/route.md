# knowledge-fetch route

`route.md` 用来沉淀可重复运行的命令。确认 knowbase 是否存在、获取 onetool token 等依赖打通放在仓库外层 `instruction.md`；本文件只提醒依赖检查，并给出数据拉取时可复用的运行方式。

## 检查 knowbase 是否存在

```bash
if command -v knowbase >/dev/null 2>&1; then
  KNOWBASE="$(command -v knowbase)"
else
  KNOWBASE="$(find "$HOME/.knowbase" -path '*/bin/knowbase' -type f 2>/dev/null | sort -V | tail -1)"
fi
test -n "$KNOWBASE" || { echo "knowbase not found; install it using instruction.md first"; exit 1; }
DISABLE_KNOWBASE_UPDATE=1 "$KNOWBASE" login status
```

## 检查认证

优先临时使用 onetool 个人 Token：

```bash
export COMATE_AUTH_TOKEN="<Bearer token>"
DISABLE_KNOWBASE_UPDATE=1 "$KNOWBASE" login status
```

运行完成后清理：

```bash
unset COMATE_AUTH_TOKEN
```

如果用户还没有 onetool 个人 Token，引导用户打开 `https://console.cloud.baidu-int.com/onetool/auth-manage/my-services`，点击“复制个人 Token”，把复制结果发给 agent 或复制到剪贴板后告知 agent，再由 agent 在当前 shell 临时设置 `COMATE_AUTH_TOKEN`。不要把 token 写进仓库、配置模板或沉淀文档。

## 拉如流群聊历史：用户已给群 ID

适用：用户明确给了如流群 ID，或已经从其他来源拿到群 ID。

先尽量校验 dodo 是否在群内：如果有群名或成员线索，用 `enterprise-search` 搜群查看候选结果里的 `m_names`、群名和描述；如果只有群 ID 且无法从通讯录搜索到成员列表，可以继续尝试拉取，但要在回复里说明“是否可抓取以 knowbase 返回为准”。

默认时间范围：上周。计算上周一 00:00:00 到上周日 23:59:59 的毫秒时间戳后写入配置；如果用户指定时间范围，按用户指定范围。

生成配置：

```yaml
version: "1.0"

meta:
  projectId: "00000000-0000-0000-0000-000000000001"
  version: "1.0.0"
  description: "Fetch infoflow group messages"
  owner: "<uuap>@baidu.com"

storage:
  basePath: "/tmp/knowbase-output-group-<groupId>"

sources:
  - type: "infoflow_group_message"
    enabled: true
    filters:
      - groupId: "<groupId>"
        startTimeStamp: <last-week-monday-00-ms>
        endTimeStamp: <last-week-sunday-235959-ms>
    output:
      exportType: "md"

entrypoint:
  type: "rule"
```

执行：

```bash
export COMATE_AUTH_TOKEN="<Bearer token>"
DISABLE_KNOWBASE_UPDATE=1 "$KNOWBASE" -c /path/to/infoflow-group-message.yaml
unset COMATE_AUTH_TOKEN
```

输出位置：

```text
<basePath>/knowledge_usage_readme.md
<basePath>/infoflow_group_message/<groupName>_<groupId>.md
<basePath>/infoflow_group_message/infoflow_group_message_usage.md
```

如果返回权限不足、机器人不在群、当前身份不是群成员等错误，告诉用户：只有 dodo 在群内且当前身份有权限的群才能抓取聊天记录；请把 dodo 拉进群或补齐权限后重试。

## 拉如流群聊历史：用户要求看所有相关群聊

适用：用户没有给群 ID，而是要求按群名、成员名、主题线索查看多个群聊。

第一步：先用 `enterprise-search` 搜群，拿候选 `gid`、群名、成员列表和群规模信息。

```bash
SANDBOX_USERNAME="<uuap>" python3 "$HOME/.codex/skills/enterprise-search/scripts/address_search.py" --type group --q "<群名或成员名或主题线索>"
```

第二步：优先筛选 `m_names`、群名、描述等结果中能看到 dodo 或用户明确确认 dodo 已在群内的群。`address_search.py` 只能辅助判断候选群，最终能否拉取仍以 knowbase 返回为准。

第三步：对筛选后的每个群，按“用户已给群 ID”的配置方式抓取上周消息。

第四步：回复用户时说明：

- 只抓取了 dodo 在群内或可访问的群。
- 如果某些群权限不足、机器人不在群或当前身份不在群，已经跳过或失败。
- 如需补抓，请把 dodo 拉进群并确认当前身份有权限后重试。

## 维护

如果 `infoflow_group_message` 的配置字段、认证方式、默认时间范围、输出路径或权限错误处理经实测变化，更新本文件。不要写真实群名、群号、token 或内部业务内容。
