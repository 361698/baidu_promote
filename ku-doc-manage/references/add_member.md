# 添加文档成员

为文档添加成员并设置访问权限。

## 请求参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| doc-id | string | 是 | - | 文档ID |
| usernames | array | 是 | - | 用户名列表(邮箱前缀) |
| role | string | 否 | DocReader | 角色名称:DocReader(可读)、DocMember(可编辑)、DocAdmin(管理员) |

## 响应示例

```json
{
  "returnCode": 200,
  "returnMessage": "SUCCESS",
  "result": {}
}
```

## CLI调用示例

```bash
# 添加只读成员（默认 DocReader）
ku add-member --doc-id WKoT7ltTnjU1oW --usernames zhangsan,lisi

# 添加可编辑成员
ku add-member --doc-id WKoT7ltTnjU1oW --usernames zhangsan --role DocMember

# 添加管理员
ku add-member --doc-id WKoT7ltTnjU1oW --usernames zhangsan --role DocAdmin
```