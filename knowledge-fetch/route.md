# knowledge-fetch route

依赖：`knowbase` 客户端；优先使用 `COMATE_AUTH_TOKEN`，也可使用 knowbase 本地 UGate 登录。

## 安装与认证

安装 knowbase：

```bash
/bin/bash -c "$(curl -fsSL http://knowbase-client.bj.bcebos.com/knowbase/install.sh)"
```

检查：

```bash
which knowbase
knowbase login status
```

临时使用 onetool 个人 Token：

```bash
export COMATE_AUTH_TOKEN="<Bearer token>"
knowbase login status
```

运行结束后：

```bash
unset COMATE_AUTH_TOKEN
```

## 直接下载链接

```bash
knowbase download "https://console.cloud.baidu-int.com/devops/icode/repos/<repo>/tree/<branch>"
```

支持链接类型以 `SKILL.md` 和 `references/config-schema.md` 为准。

## 拉如流群聊历史

先用 `enterprise-search` 搜群拿 `gid`：

```bash
SANDBOX_USERNAME="<uuap>" python3 "$HOME/.codex/skills/enterprise-search/scripts/address_search.py" --type group --q "群名或成员名"
```

写配置文件：

```yaml
version: "1.0"

meta:
  projectId: "00000000-0000-0000-0000-000000000001"
  version: "1.0.0"
  description: "Fetch recent infoflow group messages"
  owner: "<uuap>@baidu.com"

storage:
  basePath: "/tmp/knowbase-output-group"

sources:
  - type: "infoflow_group_message"
    enabled: true
    filters:
      - groupId: "<groupId>"
        startTimeStamp: 1767225600000
        endTimeStamp: 1769817599000
    output:
      exportType: "md"

entrypoint:
  type: "rule"
```

执行：

```bash
export COMATE_AUTH_TOKEN="<Bearer token>"
knowbase -c /path/to/infoflow-group-message.yaml
unset COMATE_AUTH_TOKEN
```

输出位置：

```text
<basePath>/knowledge_usage_readme.md
<basePath>/infoflow_group_message/<groupName>_<groupId>.md
<basePath>/infoflow_group_message/infoflow_group_message_usage.md
```

## 拉 iCode 仓库

```yaml
version: "1.0"
meta:
  projectId: "00000000-0000-0000-0000-000000000002"
  version: "1.0.0"
  description: "Fetch repo"
  owner: "<uuap>@baidu.com"
storage:
  basePath: "/tmp/knowbase-output-repo"
sources:
  - type: "icode_repo"
    enabled: true
    filters:
      - repo: "baidu/team/project"
        branch: "master"
        depth: "1"
entrypoint:
  type: "rule"
```

```bash
knowbase -c /path/to/repo.yaml
```

## 维护

如果某类 source 的最小配置、认证方式或输出路径经实测变化，更新本文件。不要写真实群名、仓库名、token 或内部业务内容。
