# 文档索引（链接 ↔ 文档名 ↔ 作者）

用途：记录处理过的 KU 文档，方便用户后续直接说文档名时定位链接与 ID，免去重新搜。
维护：每当创建、更新或用户告知一篇文档，就在下表追加/更新一行；链接含 docGuid、repositoryGuid 两个 ID。
边界：只存文档名、作者、链接、ID，不写 token、AK/SK、正文敏感内容。
下面是 mock 占位，真实条目在本机运行时按需追加。

| 文档名 | 作者 | 链接 | docGuid | repositoryGuid |
| --- | --- | --- | --- | --- |
| 示例产品方案 | zhangsan | https://ku.baidu-int.com/knowledge/xxx/doc/yyy | yyy | xxx |
| 示例周报汇总 | lisi | https://ku.baidu-int.com/knowledge/aaa/doc/bbb | bbb | aaa |
