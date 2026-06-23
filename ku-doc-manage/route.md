# ku-doc-manage route

本文件只沉淀可运行命令，不承载内容结构和写作约束。写入、创建、编辑、覆盖、追加或发布 KU 文档正文前，必须先读 `SKILL.md` 首要提示和 `experiment.md`，再使用本文件选命令。

先设置：

```bash
export SANDBOX_USERNAME="<uuap>"
export SKILL="$HOME/.codex/skills/ku-doc-manage"
export KU="$SKILL/bin/ku"
chmod +x "$KU"
```

注意：`SANDBOX_USERNAME` 必须在实际执行 KU 子进程的环境里存在。不要只在外层说明里写 username，也不要只传 `--username` 参数后省略环境变量；否则包装器可能仍会进入认证提示或返回开放应用认证错误。

KU CLI 有些 API 错误可能仍以 shell 退出码 `0` 返回。自动化验收时必须检查输出 JSON 里的 `success`、`status`、`returnCode`，不要只看命令退出码。

如已知本机有对应平台二进制，也可以把 `KU` 改成 `"$SKILL/bin/ku-darwin-arm64"` 等直调路径。

## 认证（单一链路）

只用本机 UGate token，不要走数字员工 / OpenAPI / 自动降级。缓存文件：`~/.config/uuap/.eac_ugate_token_<uuap>`，文件名靠 `SANDBOX_USERNAME` 定位。

运行前自检：

```bash
SANDBOX_USERNAME="<uuap>" bash "$HOME/.codex/skills/ku-doc-manage/scripts/check-deps.sh"
```

缓存 token（用户先在浏览器打开 `https://uuap.baidu.com/agent/token` 并复制，确认后再跑；脚本只读一次，不复述/落盘完整 token）：

```bash
# 剪贴板
bash "$HOME/.codex/skills/ku-doc-manage/scripts/cache-ugate-token.sh" "<uuap>"
# stdin（纯终端/沙箱或用户已贴出 token）
bash "$HOME/.codex/skills/ku-doc-manage/scripts/cache-ugate-token.sh" "<uuap>" --stdin
```

失败别先重做认证：缓存在却报认证失败，多是 `SANDBOX_USERNAME` 没进子进程，补 `export` 即可；创建/编辑被拒、`canUpdate=false` 是没写权限，不是认证问题，`--username` 不能提权。详见 SKILL.md「编辑/创建失败的排查」。

## 文档读取

按 URL 读 Markdown：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; "$KU" query-content --url "https://ku.baidu-int.com/knowledge/A/B/C/D" --protocol markdown --show-doc-info'
```

按 URL 读编辑器 JSON：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; "$KU" query-content --url "https://ku.baidu-int.com/knowledge/A/B/C/D" --protocol json --show-doc-info'
```

按 docId 读评论：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; "$KU" query-comments --doc-id "<docGuid>" --page-num 1 --page-size 20'
```

查子文档列表：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; "$KU" query-repo --repo-id "<repositoryGuid>" --parent-doc-id "<parentDocGuid>" --page-num 1 --page-size 50'
```

## 创建文档

先查个人知识库 ID：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; "$KU" query-user-info --username "$SANDBOX_USERNAME"'
```

稳定创建可见正文：先创建空文档，再用 `cover` 写首条正文，再发布，再读回。首条正文必须用 `cover`，不要用 `append`——`create-mode empty` 会留一张含空段落的空卡片，`append` 会在其后另起新卡片，导致正文上方多出一张空白卡片；`cover` 一次性替换全部内容即可消除。后续追加小节才用 `append`。

完整正式文档不要用 Markdown 原文写正文。Markdown 可以作为本地草稿或读回格式，但写入 KU 时要转换成编辑器 JSON 节点，再用 `edit-content --editor-mode cover` 覆盖全文。特别是表格：不能把 `|日期|进展|影响|` 这类 Markdown 表格行写进 `paragraph`，否则 KU 页面会直接显示管道符纯文本。

错误示例（会显示成纯文本）：

```json
{"type":"paragraph","children":[{"text":"|日期|进展|影响|"}]}
```

正确示例（必须是真表格节点；完整列宽和 cell data 见下文表格 mock）：

```json
{"type":"table","data":{"headless":false,"width":[140,280,280]},"children":[{"type":"table-row","children":[{"type":"table-cell","data":{"rowspan":1,"colspan":1},"children":[{"type":"paragraph","children":[{"text":"日期"}]}]}]}]}
```

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; CREATE="$("$KU" create-doc --repo-id "<repositoryGuid>" --username "$SANDBOX_USERNAME" --title "文档标题" --create-mode empty --process-images=false)"; DOC_ID="$(printf "%s" "$CREATE" | sed -n "s/.*\"docGuid\": *\"\([^\"]*\)\".*/\1/p" | head -1)"; OPS='\''[{"mode":"cover","withNewCard":true,"json":[{"type":"paragraph","children":[{"text":"正文内容"}]}]}]'\''; "$KU" edit-content --doc-id "$DOC_ID" --username "$SANDBOX_USERNAME" --editor-mode cover --operations "$OPS"; "$KU" publish-doc --doc-id "$DOC_ID" --username "$SANDBOX_USERNAME"; "$KU" query-content --doc-id "$DOC_ID" --protocol markdown --show-doc-info'
```

创建子文档时加 `--parent-doc-id`：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; "$KU" create-doc --repo-id "<repositoryGuid>" --parent-doc-id "<parentDocGuid>" --username "$SANDBOX_USERNAME" --title "子文档标题" --create-mode empty --process-images=false'
```

## 编辑文档

追加小节：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; OPS='\''[{"mode":"append","withNewCard":true,"json":[{"type":"heading","level":2,"children":[{"text":"新增小节"}]},{"type":"paragraph","children":[{"text":"新增正文。"}]}]}]'\''; "$KU" edit-content --doc-id "<docGuid>" --username "$SANDBOX_USERNAME" --editor-mode append --operations "$OPS"; "$KU" publish-doc --doc-id "<docGuid>" --username "$SANDBOX_USERNAME"; "$KU" query-content --doc-id "<docGuid>" --protocol markdown --show-doc-info'
```

替换、删除、中间插入、改表格行、完整文档重写：先 `query-content --protocol json` 备份并定位节点，再构造 KU 编辑器 JSON，用 `edit-content --editor-mode cover` 写回，再 `publish-doc`，最后读回确认。不要把 `result.content[0]` 的标题节点写进正文 payload。

## 附件和图片

上传附件：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; "$KU" upload-attachment --doc-id "<docGuid>" --file "/absolute/path/file.png"'
```

图片节点、表格节点、附件卡片结构见 `experiment.md` 和 `references/edit_content.md`。

图片插入最短稳定格式：

```text
先 upload-attachment 拿 attachId，再把 image.src 写成：
https://rte.weiyun.baidu.com/wiki/attach/image/api/imageDownloadAddress?attachId=<attachId>&docGuid=<docGuid>
```

表格必须写完整 `table` 节点，否则 Web 端空白不渲染（markdown 读回看似有表也算坏）：`table.data.width` 数组长度必须等于列数（两列写两个宽度），每个 `table-cell.data` 必须写 `{"rowspan":1,"colspan":1}`，建议带 `table.data.headless`；省略 `data` 会被默认成 `width:[106]` 单列、`colspan:0/rowspan:0` 导致整表不渲染。表头灰底给首行每个 `table-cell.data.backgroundColor` 写 `rgb(231, 230, 230)`。写完用 `query-content --protocol json` 核对 `width` 列数与每个 cell 的 `colspan/rowspan` 均为 1。两列表格 mock：

```json
{"type":"table","data":{"headless":true,"width":[160,520]},"children":[
  {"type":"table-row","children":[
    {"type":"table-cell","data":{"rowspan":1,"colspan":1,"backgroundColor":"rgb(231, 230, 230)"},"children":[{"type":"paragraph","children":[{"text":"表头A","bold":true}]}]},
    {"type":"table-cell","data":{"rowspan":1,"colspan":1,"backgroundColor":"rgb(231, 230, 230)"},"children":[{"type":"paragraph","children":[{"text":"表头B","bold":true}]}]}
  ]},
  {"type":"table-row","children":[
    {"type":"table-cell","data":{"rowspan":1,"colspan":1},"children":[{"type":"paragraph","children":[{"text":"行1A"}]}]},
    {"type":"table-cell","data":{"rowspan":1,"colspan":1},"children":[{"type":"paragraph","children":[{"text":"行1B"}]}]}
  ]}
]}
```

## 高风险操作

删除文档前必须二次确认：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; "$KU" delete-doc --doc-id "<docGuid>" --username "$SANDBOX_USERNAME"'
```

移动、公开权限同理先确认，再执行 `move-doc` 或 `change-scope`。

## 维护

如果命令路径、参数、认证方式在实测中需要调整，把可复用的一行命令更新到本文件。不要写真实 token、真实文档链接或用户私密文档名。
