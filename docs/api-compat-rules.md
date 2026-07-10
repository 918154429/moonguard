# MoonGuard API 兼容性规则

本文档说明 MoonGuard 如何把 `.mbti` 公共接口变化映射为 SemVer 建议。规则以“避免把潜在破坏性变化误报为兼容”为原则；如果工具无法证明某个嵌套成员的新增对现有调用方安全，就采用保守的 `major` 判定。

## 影响级别

| 接口变化 | 建议 | 理由 |
| --- | --- | --- |
| 无公共 API 变化，仅格式、空白或注释变化 | `patch` | 不改变调用方可见接口 |
| 新增普通顶层公共声明，如函数、类型、结构体、枚举、trait、常量 | `minor` | 现有调用方无需使用新符号 |
| 新增 `derive` | `minor` | 为类型增加能力，通常不要求现有调用方修改代码 |
| 删除公共声明或嵌套成员 | `major` | 现有引用会失效 |
| 修改公共声明或嵌套成员的签名 | `major` | 参数、返回值、类型、可见性或约束变化可能使现有代码无法编译 |
| 顶层声明种类改变，如 `struct` 变为 `enum` | `major` | 即使名称不变，其构造和匹配方式也发生变化 |
| 新增结构体字段 | `major` | 现有结构体字面量、构造代码和完整字段处理可能需要补充新字段 |
| 新增枚举或 `suberror` constructor | `major` | 现有穷尽匹配可能不再穷尽，调用方需要处理新分支 |
| 新增 trait 必需方法 | `major` | 现有 trait 实现必须新增方法才能继续满足接口 |

当一次比较同时包含多种变化时，最终建议取其中最高级别：`major` 高于 `minor`，`minor` 高于 `patch`。

## 保守嵌套成员规则

MoonGuard 将以下新增统一判为 `major`：

- `field`：结构体字段；
- `constructor`：枚举和 `suberror` constructor；
- `trait-method`：trait 必需方法。

这些规则有意比“所有新增 API 都是 minor”更严格。顶层新增只扩展命名空间，而嵌套成员新增会改变已有类型或 trait 的封闭形状，可能直接破坏结构体构造、穷尽匹配或既有 trait 实现。因此，MoonGuard 不把它们与普通顶层新增混为一类。

目前解析的 `.mbti` 信息不足以可靠区分“带兼容默认实现的方法”和“所有实现都必须提供的方法”。为避免漏报，新增 trait 方法按必需方法处理。项目若能通过额外语义信息证明某个新增方法兼容，可以使用 ignore rule 显式接受该变化，并在发布说明中记录原因。

## 格式规范化

容器声明的排版不属于 API 变化。MoonGuard 会把容器头与嵌套成员分别解析，因此以下写法应得到相同的 API 快照：

```moonbit
pub struct Options { mode : String }
```

```moonbit
pub struct Options {
  mode : String
}
```

同样的规范化适用于 `enum`、`trait` 和 `suberror`。单行容器包含多个成员时，MoonGuard 支持在顶层使用逗号或分号分隔；成员参数或泛型内部的逗号不会被当作成员分隔符。

格式规范化不会掩盖真实变化。例如将 `mode : String` 改为 `mode : Int`，或将 `Ok(String)` 改为 `Ok(Int)`，仍会产生一次 `major` 签名变化。

## 当前边界

- MoonGuard 以 `.mbti` 文本快照为输入，不进行完整 MoonBit 类型检查或源码级调用分析。
- attribute、可见性、泛型约束和签名文本的实质变化按 `major` 处理。
- 无法识别的公共声明会作为 `unknown` 保留在快照中，避免静默忽略潜在 API。
- ignore rule 是显式风险接受机制，不会改变默认兼容规则。

