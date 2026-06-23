# update-datasheet-records - 更新数据表记录

更新数据表中已存在的记录。

## 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| dist-id | string | 是 | 数据表ID |
| view-id | string | 是 | 视图ID |
| records | string | 是 | 更新的记录数据，必须包含recordId（可通过 get-datasheet-records 获取） |

### record_data 结构

```json
{
    "records": [
        {
            "recordId": "rec123456",
            "fields": {
                "字段名1": "新值1",
                "字段名2": "新值2"
            }
        }
    ]
}
```

## 响应字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| msg | string | 请求消息，成功为 `"SUCCESS"` |
| returnCode | int | 业务返回码，200 表示成功 |
| returnMessage | string | 业务返回消息 |
| status | int | HTTP 状态码 |
| success | bool | 请求是否成功 |
| traceId | string | 链路追踪 ID |
| result.records | list | 已更新的记录列表 |
| result.records[].recordId | string | 记录唯一 ID |
| result.records[].createdAt | long | 记录创建时间（毫秒时间戳） |
| result.records[].updatedAt | long | 记录最后更新时间（毫秒时间戳） |
| result.records[].fields | object | 更新后的字段内容，仅返回实际更新的字段 |

## 响应示例

```json
{
    "msg": "SUCCESS",
    "result": {
        "records": [
            {
                "createdAt": 1773922880000,
                "fields": {
                    "状态": "已完成"
                },
                "recordId": "recVNNHvWiNiI",
                "updatedAt": 1773922880000
            }
        ]
    },
    "returnCode": 200,
    "returnMessage": "SUCCESS",
    "status": 200,
    "success": true,
    "traceId": "689815786734395392"
}
```

## CLI调用示例

```bash
# 更新单条记录
ku update-datasheet-records --dist-id dstxRvKjhSZZJDNvpZ --view-id viwxxx --records '[{"recordId": "rec123456", "fields": {"状态": "已完成"}}]'

# 批量更新多条记录
ku update-datasheet-records --dist-id dstxRvKjhSZZJDNvpZ --view-id viwxxx --records '[{"recordId": "rec123456", "fields": {"状态": "已完成", "完成时间": 1635724800000}}, {"recordId": "rec789012", "fields": {"状态": "进行中"}}]'
```