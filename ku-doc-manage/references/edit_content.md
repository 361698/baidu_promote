# 编辑文档正文

通过编辑操作列表对文档内容进行增删改操作，支持追加、覆盖、局部编辑三种操作模式。

## 请求参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| doc-id | string | 是 | - | 文档ID |
| username | string | 是 | - | 编辑者用户名（UUAP格式，即邮箱前缀，一般是当前用户名） |
| editor-mode | string | 否 | - | 编辑模式：`append`(追加)、`cover`(覆盖)、`mdsl`(局部编辑)。不传则使用传统operations模式 |
| operations | list | 条件必需 | - | 编辑操作列表（append/cover模式或不传editor-mode时必需） |
| operation | dict | 条件必需 | - | Markdown局部编辑操作（mdsl模式必需） |

## 模式一：传统模式（append/cover）

当 `editor-mode` 为 `append`、`cover` 或不传时，使用 `operations` 参数。

## operations 操作列表说明

每个操作是一个字典，包含以下字段：

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| mode | string | 否 | `append` | 操作模式：`append`/`cover` |
| json | list | 是 | - | 编辑器 JSON 元素数组 |
| withNewCard | boolean | 否 | true | 是否使用新版卡片格式 |

### 操作模式说明

| mode | 说明 |
|------|------|
| `append` | 追加内容到文档末尾 |
| `cover` | 覆盖全文（完全替换文档所有内容） |

## 模式二：局部编辑模式（mdsl）

当 `editor-mode` 为 `mdsl` 时，使用 `operation` 参数进行基于 Markdown 的局部编辑。

> ⚠️ **mdsl 模式必须先读取文档**：执行局部编辑前，必须先调用 `query-content --doc-id <文档ID> --protocol mdhtml` 获取文档内容，用于定位目标块。

> **重要**：mdsl 模式的完整使用指南（定位规则、约束条件、决策流程、表格修改速查）请参考 [mdsl_edit_agent.md](mdsl_edit_agent.md)。

### operation 参数说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| mode | string | 是 | 操作模式：`insert_before`/`insert_after`/`replace_range`/`delete_range` |
| selectionWithEllipsis | string | 条件必需 | 按内容定位，必须为完整块/行。与 selectionByTitle 二选一 |
| selectionByTitle | string | 条件必需 | 按标题定位整节。与 selectionWithEllipsis 二选一 |
| markdown | string | 条件必需 | 要插入/替换的内容（delete_range 不需要） |

### mdsl 操作模式说明

| mode | 说明 |
|------|------|
| `insert_before` | 在定位块前插入内容 |
| `insert_after` | 在定位块后插入内容 |
| `replace_range` | 替换定位块内容 |
| `delete_range` | 删除定位块内容 |

### 定位规则摘要

- **selectionWithEllipsis**：定位对象必须是完整块/行；较长内容可用 `开头10~20字...结尾10~20字` 省略；字面量 `...` 需转义为 `\.\.\.`
- **selectionByTitle**：`## 标题` 匹配指定级别，`标题` 匹配任意级别；自动覆盖到下一同级标题前的全部内容

## json 元素格式说明

`json` 字段为编辑器节点数组，常用节点类型：

### 段落 (paragraph)
```json
{
    "type": "paragraph",
    "children": [
        {"type": "text", "text": "这是一段普通文字"}
    ]
}
```

### 标题 (heading)
```json
{
    "type": "heading",
    "level": 1,
    "children": [
        {"text": "分级标题一"}
    ]
}
```

### 有序列表 (orderedList)
```json
{
    "type": "ordered-list-item",
    "depth": 0,
    "index": 1,
    "children": [
        {"text": "11111"}
    ]
},
{
    "type": "ordered-list-item",
    "depth": 0,
    "index": 2,
    "children": [
        {"text": "222222"}
    ]
}
```

### 代码块 (codeBlock)
```json
{
    "type": "block-code",
    "language": "plain",
    "children": [
        {
            "type": "block-code-line",
            "children": [
                {"text": "这是是代码块"}
            ],
            "textIndent": 0,
            "textAlign": "left"
        }
    ]
}
```

### 图片（image）
```json
{
    "type": "image",
    "src": "https://bj.bcebos.com/ku-daas/storage/lw6JAMhc0YArEQ/cHfoPnbS1bH7Zu.png",
    "mimeType": "image/png",
    "invalid": false,
    "imageData": {
        "width": 480,
        "height": 82
    },
    "imageContainerData": {
        "x": 0,
        "y": 0,
        "width": 480,
        "height": 82
    },
    "width": 4626,
    "height": 790,
    "children": [
        {
            "text": ""
        }
    ]
}
```

### 附件（attachment）

> ⚠️ **重要**：添加附件需要两步操作，请先参考 [upload_attachment.md](upload_attachment.md) 上传附件获取 `fileId`。

**第一步：上传附件获取 fileId**
```bash
ku upload-attachment --doc-id WKoT7ltTnjU1oW --file /path/to/report.xlsx
```

响应返回：
```json
{
  "result": {
    "attachId": "f49c39d17cc24d34ae3fef0ebf295fe3",
    "name": "report.xlsx",
    "extension": "xlsx",
    "size": 3764
  }
}
```

**第二步：使用 attachId 作为 fileId 添加附件**
```json
{
    "type": "attachment",
    "fileId": "f49c39d17cc24d34ae3fef0ebf295fe3",
    "fileInfo": {
      "name": "report.xlsx",
      "size": 3764,
      "type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "extension": "xlsx"
    },
    "viewType": "card",
    "invalid": false,
    "children": [
        {
            "text": ""
        }
    ],
    "docId": "eQgfKSA7NwuXSl",
    "id": "cxsrcjBT",
    "url": ""
}
```

**字段对应关系**：

| upload-attachment 响应字段 | attachment 参数 |
|---------------------------|-----------------|
| `attachId` | `fileId` |
| `name` | `fileInfo.name` |
| `size` | `fileInfo.size` |
| `extension` | `fileInfo.extension` |

**常见文件 MIME 类型**：
| 扩展名 | MIME type |
|--------|-----------|
| xlsx | `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` |
| xls | `application/vnd.ms-excel` |
| docx | `application/vnd.openxmlformats-officedocument.wordprocessingml.document` |
| doc | `application/msword` |
| pdf | `application/pdf` |
| jpeg | `image/jpeg` |
| 其他 | `application/octet-stream` |

### 表格 (table)
```json
{
    "type": "table",
    "sticky": false,
    "data": {
      "headless": true,
      "width": [
        74,
        74
      ]
    },
    "children": [
      {
        "type": "table-row",
        "children": [
          {
            "type": "table-cell",
            "children": [
              {
                "type": "paragraph",
                "children": [
                  {
                    "text": "行1"
                  }
                ]
              }
            ],
            "data": {
              "rowspan": 1,
              "colspan": 1
            }
          },
          {
            "type": "table-cell",
            "children": [
              {
                "type": "paragraph",
                "children": [
                  {
                    "text": "行2"
                  }
                ]
              }
            ],
            "data": {
              "rowspan": 1,
              "colspan": 1
            }
          }
        ]
      }
    ]
  }
```

## 响应示例

```json
{
    "returnCode": 200,
    "returnMessage": "OK",
    "result": {
        "docGuid": "WSuIrx09hfg6zr",
        "success": true,
        "operations": [
            {
                "success": true
            }
        ]
    },
    "traceId": "694507417572758528",
    "status": 200,
    "msg": "OK",
    "success": true
}
```

## CLI调用示例

### 传统模式示例（append/cover）

```bash
# 示例1: 追加一段文字到文档末尾
ku edit-content --doc-id WKoT7ltTnjU1oW --username zhangsan \
--operations '[{"mode":"append","withNewCard":true,"json":[{"type":"paragraph","children":[{"text":"追加的新内容"}]}]}]'

# 示例2: 覆盖全文（mode=cover 会完全替换文档内容，操作不可逆）
ku edit-content --doc-id WKoT7ltTnjU1oW --username zhangsan \
--operations '[{"mode":"cover","withNewCard":true,"json":[{"type":"paragraph","children":[{"text":"新文档内容，完全替换原内容"}]}]}]'

# 示例3: 创建标题和段落
ku edit-content --doc-id WKoT7ltTnjU1oW --username zhangsan \
--operations '[{"mode":"append","withNewCard":true,"json":[{"type":"heading","level":1,"children":[{"text":"一级标题"}]},{"type":"paragraph","children":[{"text":"段落内容"}]}]}]'
```

### 局部编辑模式示例（mdsl）

```bash
# 示例4: 在指定文本后插入内容（使用行内选区定位）
ku edit-content --doc-id WKoT7ltTnjU1oW --username zhangsan \
--editor-mode mdsl \
--operation '{"mode":"insert_after","selectionWithEllipsis":"这是定位文本","markdown":"## 新插入的标题\n\n这是新插入的段落内容"}'

# 示例5: 替换指定标题下的所有内容（使用标题选区定位）
ku edit-content --doc-id WKoT7ltTnjU1oW --username zhangsan \
--editor-mode mdsl \
--operation '{"mode":"replace_range","selectionByTitle":"章节标题","markdown":"这是替换后的新内容"}'

# 示例6: 在指定位置前插入内容
ku edit-content --doc-id WKoT7ltTnjU1oW --username zhangsan \
--editor-mode mdsl \
--operation '{"mode":"insert_before","selectionWithEllipsis":"目标文本","markdown":"在目标前插入的内容"}'

# 示例7: 删除指定标题下的内容
ku edit-content --doc-id WKoT7ltTnjU1oW --username zhangsan \
--editor-mode mdsl \
--operation '{"mode":"delete_range","selectionByTitle":"要删除的章节"}'
```

## 注意事项

- `username` 必须是有权限编辑该文档的用户
- `cover` 模式会清空文档所有内容后重写，操作不可逆，请谨慎使用
- `mdsl` 模式的详细约束和最佳实践请参考 [mdsl_edit_agent.md](mdsl_edit_agent.md)

## 编辑后发布（重要）

知识库文档的编辑态和预览态是分离的。通过 `edit-content` 进行的修改仅保存在**编辑态**，其他用户在预览态看不到这些更改。

**编辑完成后必须调用发布命令**，将编辑态的修改发布到预览态：

```bash
ku publish-doc --doc-id <文档ID> --username <操作者用户名>
```

**工作流程**：
1. 调用 `edit-content` 完成内容编辑
2. 确认编辑成功（returnCode=200）
3. 调用 `publish-doc` 发布文档

## 完整编辑流程示例

```bash
# 1. 读取文档内容（mdsl 模式必须先读取）
ku query-content --doc-id WKoT7ltTnjU1oW --protocol mdhtml

# 2. 局部编辑
ku edit-content --doc-id WKoT7ltTnjU1oW --username zhangsan \
  --editor-mode mdsl \
  --operation '{"mode":"replace_range","selectionWithEllipsis":"原始内容","markdown":"修改后的内容"}'

# 3. 发布文档（编辑成功后必做）
ku publish-doc --doc-id WKoT7ltTnjU1oW --username zhangsan
```