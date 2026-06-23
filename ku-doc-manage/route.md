# ku-doc-manage route

先设置：

```bash
export SANDBOX_USERNAME="<uuap>"
export SKILL="$HOME/.codex/skills/ku-doc-manage"
export KU="$SKILL/bin/ku"
chmod +x "$KU"
```

如已知本机有对应平台二进制，也可以把 `KU` 改成 `"$SKILL/bin/ku-darwin-arm64"` 等直调路径。

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

稳定创建可见正文：先创建空文档，再追加正文，再发布，再读回。

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; CREATE="$("$KU" create-doc --repo-id "<repositoryGuid>" --username "$SANDBOX_USERNAME" --title "文档标题" --create-mode empty --process-images=false)"; DOC_ID="$(printf "%s" "$CREATE" | sed -n "s/.*\"docGuid\": *\"\([^\"]*\)\".*/\1/p" | head -1)"; OPS='\''[{"mode":"append","withNewCard":true,"json":[{"type":"paragraph","children":[{"text":"正文内容"}]}]}]'\''; "$KU" edit-content --doc-id "$DOC_ID" --username "$SANDBOX_USERNAME" --editor-mode append --operations "$OPS"; "$KU" publish-doc --doc-id "$DOC_ID" --username "$SANDBOX_USERNAME"; "$KU" query-content --doc-id "$DOC_ID" --protocol markdown --show-doc-info'
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

替换、删除、中间插入、改表格行：先 `query-content --protocol json` 备份并定位节点，再 `edit-content --editor-mode cover`，再 `publish-doc`，最后读回确认。不要把 `result.content[0]` 的标题节点写进正文 payload。

## 附件和图片

上传附件：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; "$KU" upload-attachment --doc-id "<docGuid>" --file "/absolute/path/file.png"'
```

图片节点、表格节点、附件卡片结构见 `experiment.md` 和 `references/edit_content.md`。

## 高风险操作

删除文档前必须二次确认：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"; "$KU" delete-doc --doc-id "<docGuid>" --username "$SANDBOX_USERNAME"'
```

移动、公开权限同理先确认，再执行 `move-doc` 或 `change-scope`。

## 维护

如果命令路径、参数、认证方式在实测中需要调整，把可复用的一行命令更新到本文件。不要写真实 token、真实文档链接或用户私密文档名。
