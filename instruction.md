# baidu_promote 安装与验收指令

本文是给 agent 看的执行指令，不是给用户看的教程。你的目标是在一台新电脑上，帮助用户尽快安装、打通并验收这些百度内部数据源读写 skill。

仓库保留官方 skill 主体，只增加三类增强层：

- `route.md`：最短命令表。需要读写数据时先从这里找命令。
- `experiment.md`：可复用经验。需要处理格式、风格、覆盖/追加、表格、图片、摘要等问题时先看这里。
- `SKILL.md`：原 skill 入口，只额外提示使用 `route.md` 和 `experiment.md`，不要把一次性测试题目写入 skill 本体。

## 1. 先问用户安装范围

先问用户希望安装哪些 skill，并推荐默认全装。话术可以简洁一点：

```text
我建议默认把四个都装上：ku-doc-manage、enterprise-search、get-ugate-token、knowledge-fetch。
它们配合起来最有用：可以读写 KU/如流文档、创建和编辑文档、做企业内搜、搜人搜群、拉群聊历史到本地。比如你后续要做项目资料整理、根据群聊沉淀文档、找历史文档、把结果写回 KU，这几个会连成一条完整链路。
你要全部安装，还是只安装其中几个？
```

如果用户没有明确选择，按“全部安装”执行。

## 2. 安装 skill 文件夹

Codex 默认安装到：

```bash
mkdir -p "$HOME/.codex/skills"
cp -R /path/to/baidu_promote/ku-doc-manage "$HOME/.codex/skills/"
cp -R /path/to/baidu_promote/enterprise-search "$HOME/.codex/skills/"
cp -R /path/to/baidu_promote/get-ugate-token "$HOME/.codex/skills/"
cp -R /path/to/baidu_promote/knowledge-fetch "$HOME/.codex/skills/"
```

Claude Code 默认安装到：

```bash
mkdir -p "$HOME/.claude/skills"
cp -R /path/to/baidu_promote/ku-doc-manage "$HOME/.claude/skills/"
cp -R /path/to/baidu_promote/enterprise-search "$HOME/.claude/skills/"
cp -R /path/to/baidu_promote/get-ugate-token "$HOME/.claude/skills/"
cp -R /path/to/baidu_promote/knowledge-fetch "$HOME/.claude/skills/"
```

从 GitHub 安装时，先 clone 仓库，再复制对应目录：

```bash
git clone git@github.com:361698/baidu_promote.git /tmp/baidu_promote
mkdir -p "$HOME/.codex/skills"
cp -R /tmp/baidu_promote/ku-doc-manage "$HOME/.codex/skills/"
cp -R /tmp/baidu_promote/enterprise-search "$HOME/.codex/skills/"
cp -R /tmp/baidu_promote/get-ugate-token "$HOME/.codex/skills/"
cp -R /tmp/baidu_promote/knowledge-fetch "$HOME/.codex/skills/"
```

如果目标 skill 目录已存在，先备份再覆盖：

```bash
ts="$(date +%Y%m%d-%H%M%S)"
for s in ku-doc-manage enterprise-search get-ugate-token knowledge-fetch; do
  if [ -d "$HOME/.codex/skills/$s" ]; then
    mv "$HOME/.codex/skills/$s" "$HOME/.codex/skills/$s.bak.$ts"
  fi
done
```

## 3. skill 与依赖矩阵

| skill | 用途 | 必要依赖 | 可选依赖 |
|---|---|---|---|
| `get-ugate-token` | 缓存 UGate，供其他 skill 调百度内部接口 | Python3、用户 UUAP、UGate token 页面内容 | `aigate-cli` 授权开关 |
| `ku-doc-manage` | KU/如流知识库文档读取、创建、编辑、发布、删除、评论、权限、附件、表格、数据表 | UGate 缓存、`SANDBOX_USERNAME`、`bin/ku` 可执行 | 平台二进制自动下载缓存 |
| `enterprise-search` | 企业内搜、知识库搜索、搜人、搜群、会议、周报、OKR | Python3、UGate 缓存、`SANDBOX_USERNAME` | 无 |
| `knowledge-fetch` | 拉 iCode、iCafe、iAPI、知识方舟、如流群聊历史到本地 | `knowbase` 客户端、`COMATE_AUTH_TOKEN` 或 knowbase UGate 登录 | `wget`，用于官方安装脚本 |

## 4. 按依赖完成打通

### 4.1 询问 UUAP

先问用户百度 UUAP，也就是邮箱前缀，例如 `zhangsan`。后续命令统一设置：

```bash
export SANDBOX_USERNAME="<uuap>"
```

### 4.2 引导用户获取并缓存 UGate

让用户打开：

```text
https://uuap.baidu.com/agent/token
```

说明要点：

- 如果页面没有显示 token，说明浏览器还没过百度网关/SSO，让用户先完成登录，再刷新页面。
- 用户可以把 token 页面内容发到聊天里，也可以复制到剪贴板后告诉 agent。
- agent 不要复述完整 token，不要把 token 写入仓库、文档或日志摘要。
- 不要启动一个命令长时间等待用户输入。正确节奏是：先让用户打开页面并复制或发送 token，等用户回复后，再运行缓存命令。

缓存命令：

```bash
cd "$HOME/.codex/skills/get-ugate-token"
USER_MESSAGE="ugate token: <用户复制的页面内容或纯JWT>" python3 getUgateToken.py "<uuap>"
```

验证缓存文件：

```bash
test -f "$HOME/.config/uuap/.eac_ugate_token_<uuap>" && echo "UGate cached"
```

### 4.3 打通 KU CLI

```bash
chmod +x "$HOME/.codex/skills/ku-doc-manage/bin/ku"
SANDBOX_USERNAME="<uuap>" "$HOME/.codex/skills/ku-doc-manage/bin/ku" query-user-info --username "<uuap>"
```

如果失败，先读 `ku-doc-manage/route.md`，修正路径、权限、认证或参数；可复用修正写回 `route.md`。

### 4.4 打通企业搜索

```bash
cd "$HOME/.codex/skills/enterprise-search"
SANDBOX_USERNAME="<uuap>" python3 scripts/ku_search.py --word "测试关键词" --page 1 --page-size 5
```

如果失败，先读 `enterprise-search/route.md`；可复用修正写回 `route.md`。

### 4.5 打通 knowbase

`knowledge-fetch` 用于把知识源拉到本地，尤其是如流群聊历史。

安装：

```bash
/bin/bash -c "$(curl -fsSL http://knowbase-client.bj.bcebos.com/knowbase/install.sh)"
```

如果安装脚本因为缺少 `wget` 失败，先补齐 `wget`，或使用已安装的完整 knowbase 目录。不要只拷贝单个 `bin/knowbase`，它运行时还依赖旁边的版本文件。

如果 `knowbase` 不在 PATH，不要立即判定未安装。先探测本机是否已有完整目录，并用绝对路径直调：

```bash
if command -v knowbase >/dev/null 2>&1; then
  KNOWBASE="$(command -v knowbase)"
else
  KNOWBASE="$(find "$HOME/.knowbase" -path '*/bin/knowbase' -type f 2>/dev/null | sort -V | tail -1)"
fi
test -n "$KNOWBASE" || { echo "knowbase not found"; exit 1; }
DISABLE_KNOWBASE_UPDATE=1 "$KNOWBASE" login status
```

让用户打开：

```text
https://console.cloud.baidu-int.com/onetool/auth-manage/my-services
```

让用户点击“复制个人 Token”，然后 agent 在当前 shell 临时设置：

```bash
export COMATE_AUTH_TOKEN="<用户复制的Bearer token>"
"$KNOWBASE" login status
```

运行完成后：

```bash
unset COMATE_AUTH_TOKEN
```

## 5. 最小验收用例

这些用例只用于新电脑安装后的验收，不要写进各 skill 的 `SKILL.md`。执行时如果用户只想验收部分能力，就只做对应部分。

### 5.1 KU 创建、读取、编辑、发布

目标：在用户个人知识库创建一个标题为 `hello world` 的文档，正文写一句验收说明，读回确认标题、正文、链接。

执行方式：读 `ku-doc-manage/route.md`，使用稳定流程：

1. `query-user-info` 拿个人知识库 ID。
2. `create-doc --create-mode empty` 创建空文档。
3. `edit-content --editor-mode append` 写正文。
4. `publish-doc` 发布。
5. `query-content --protocol markdown --show-doc-info` 读回。

### 5.2 企业搜索搜到刚创建的文档

目标：用 `enterprise-search` 搜索 `hello world`，确认能返回刚创建的 KU 文档或至少能返回相关搜索结果。

执行方式：读 `enterprise-search/route.md`，优先使用：

```bash
SANDBOX_USERNAME="<uuap>" python3 scripts/ku_search.py --word "hello world" --page 1 --page-size 10
```

### 5.3 下载/读取这个文档

目标：用 KU 文档链接或 `docGuid` 再读一次刚创建的文档，确认可下载/可读取为 Markdown 和 JSON。

执行方式：读 `ku-doc-manage/route.md`，分别跑：

```bash
"$HOME/.codex/skills/ku-doc-manage/bin/ku" query-content --url "<hello-world-url>" --protocol markdown --show-doc-info
"$HOME/.codex/skills/ku-doc-manage/bin/ku" query-content --url "<hello-world-url>" --protocol json --show-doc-info
```

### 5.4 添加表格，首行置灰

目标：在刚创建的文档里追加一个表格，主题随机选择一首闽南、粤语或国语老歌并做简短介绍。表格首行置灰。

执行方式：读 `ku-doc-manage/experiment.md` 和 `ku-doc-manage/references/edit_content.md`，使用 `edit-content --editor-mode append` 追加 KU `table` 节点，再 `publish-doc`，最后读回确认表格存在。

### 5.5 插入图片

目标：给同一篇验收文档插入一张图片。图片可以是本机临时生成的简单封面图或用户提供的图片。

执行方式：读 `ku-doc-manage/route.md` 的附件和图片部分。先 `upload-attachment`，再把返回的 `attachId` 组装成 image 节点，追加后发布并读回确认。

### 5.6 如流群聊历史获取

目标：验证 `knowledge-fetch` 能拉如流群聊历史。

先让用户选择一个可测试群，并把 `dodo` 拉进这个群。让用户提供群号，或用 `enterprise-search` 的搜群能力找 `gid`。

执行方式：读 `knowledge-fetch/route.md`，生成 `infoflow_group_message` 配置，设置 `COMATE_AUTH_TOKEN` 后运行：

```bash
knowbase -c /path/to/infoflow-group-message.yaml
```

验收输出：

- 本地生成 `knowledge_usage_readme.md`。
- 本地生成 `infoflow_group_message/...md`。
- 能看到目标时间范围内的群聊内容或明确的权限错误。

## 6. 维护规则

如果读写失败是因为命令、路径、依赖、认证、参数不对，并且修正方式可复用，更新对应 skill 的 `route.md`。

如果用户指出读写格式、写作风格、内容长短、表格结构、覆盖/追加策略、信息编造等问题，并且经验可复用，更新对应 skill 的 `experiment.md`。

不要把用户具体文档名、真实链接、真实群名、token、AK/SK 写进 `route.md` 或 `experiment.md`。需要示例时使用 mock 占位。
