# 更新文档成员权限

更新文档已有成员的访问权限。

## 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| doc-id | string | 是 | 文档ID |
| username | string | 是 | 待更新的用户名(邮箱前缀) |
| role | string | 是 | 新的角色名称:DocReader、DocMember、DocAdmin |

## 响应示例

```json
{
    "returnCode": 200,
    "returnMessage": "OK",
    "result": {
        "docGuid": "1xosIYvQX3qxeI",
        "success": true,
        "memberResultList": [
            {
                "memberType": 5,
                "memberGuid": "zhangsan"
            }
        ]
    },
    "traceId": "123456789012345678"
}
```

## CLI调用示例

```bash
# 将成员升级为可编辑权限
ku update-member --doc-id WKoT7ltTnjU1oW --username zhangsan --role DocMember

# 降级为只读
ku update-member --doc-id WKoT7ltTnjU1oW --username zhangsan --role DocReader
```