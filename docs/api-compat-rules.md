# MoonGuard API 兼容性规则

本文档说明 MoonGuard 如何把 `.mbti` 公共接口变化映射为 SemVer 建议。规则以“避免把潜在破坏性变化误报为兼容”为原则；如果工具无法证明某个嵌套成员的新增对现有调用方安全，就采用保守的 `major` 判定。

## 影响级别

| 接口变化 | 建议 | 理由 |
| --- | --- | --- |
| 无公共 API 变化，仅格式、空白或注释变化 | `patch` | 不改变调用方可见接口 |
| 新增普通顶层公共声明，如函数、类型、结构体、枚举、trait、常量 | `minor` | 现有调用方无需使用新符号 |
| 新增完整容器及其字段、构造器或 trait 方法 | `minor` | 新容器的嵌套成员尚不存在既有调用方，不重复判定为 breaking change |
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

如果整个 struct、enum、suberror 或 trait 都是本次新增加的，其成员不会被重复报告为独立的 breaking change；MoonGuard 只报告新增顶层容器，并给出 `minor` 建议。删除整个容器时同样只报告顶层删除，避免把一个决策膨胀为容器及全部成员的重复变化。只有容器在旧、新快照中都存在时，嵌套成员规则才单独生效。

目前解析的 `.mbti` 信息不足以可靠区分“带兼容默认实现的方法”和“所有实现都必须提供的方法”。为避免漏报，新增 trait 方法按必需方法处理。项目若能通过额外语义信息证明某个新增方法兼容，可以使用可审计 policy rule 显式接受该变化，并在发布说明中记录原因。

## 目录快照的 API 身份

目录比较中，API 的逻辑身份由“父目录 package scope + 符号身份”组成，具体 `.mbti` 文件名只作为来源信息。举例：

- `pkg/a.mbti` 中的 `render` 移到 `pkg/b.mbti`，逻辑身份仍为 `pkg::render`，因此是 `patch` 且没有 API change；
- `pkg-a/a.mbti` 与 `pkg-b/b.mbti` 中的同名 `render` 属于不同 package scope，互不覆盖；
- 同一 package scope 内重复定义同种类、同名称符号，仍产生 `duplicate-symbol` 诊断；
- 诊断保留原始文件路径，便于定位，路径不参与同包内的兼容性身份判断。

这避免了纯文件整理被误报为一次删除加一次新增，同时保留跨包移动和真实重复定义的可见性。

## 可审计兼容性策略

策略文件每行一条规则：

```text
allow CHANGE_KIND ITEM_KIND NAME [until VERSION] [max_matches N] reason TEXT...
```

例如：

```text
allow changed fn render until 0.2.0 max_matches 1 reason render migration reviewed
allow removed fn legacy_* max_matches 2 reason legacy cleanup approved
```

- `CHANGE_KIND` 可为 `added`、`removed`、`changed` 或 `*`；
- `ITEM_KIND` 使用 API 种类或 `*`；
- `NAME` 支持 `*` 通配；
- `until` 是可选的严格 `major.minor.patch` 截止版本，目标版本超过它即过期；
- `max_matches` 必须为正整数，省略时默认为 `1`；
- `reason` 必填且不可为空。

策略求值同时保留 `original_report` 与移除已接受变化后的 `effective_report`，并输出每项 accepted change 所属规则、理由、截止版本、预算以及策略诊断。SemVer 检查和 release plan 基于 effective report，但审计输出不会隐藏原始 breaking change。

策略采用 fail-closed 行为：解析错误、规则过期、需要但缺失目标版本、目标版本无效或匹配数超过预算时，规则不接受任何变化，并产生错误诊断。未命中规则和重叠规则产生警告；多个有效规则匹配同一变化时，由第一条规则拥有审计记录。

CLI 使用 `--policy-file PATH` 和可选的 `--policy-version VERSION`。`check`、`check-dir` 与 `release-plan` 在未显式指定策略版本时使用 `--next`。配置文件对应 `policy_file` 与 `policy_version`。策略文件与旧 `--ignore-file` 互斥，`inventory-dir` 不支持策略文件。

退出码约定：

- `0`：有效报告或版本提升满足 effective recommendation；
- `1`：输入与策略有效，但版本提升不足；
- `2`：输入、快照、配置或策略诊断阻止可靠判定。

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
- 旧 ignore rule 仍作为兼容功能存在，但会直接过滤变化；新的 policy rule 是推荐的风险接受机制，因为它保留原始报告和完整审计轨迹。
