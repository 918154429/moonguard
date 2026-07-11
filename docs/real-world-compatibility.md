# 真实 MoonBit 接口兼容性抽样

本报告使用 15 个公开 GitHub 仓库中的真实 `pkg.generated.mbti`，验证
MoonGuard 对生态接口快照的解析能力。样本固定到完整 commit SHA，来源、
许可证、原始 URL 与 SHA-256 见
[`fixtures/real/SOURCES.md`](../fixtures/real/SOURCES.md) 和
[`fixtures/real/metadata.json`](../fixtures/real/metadata.json)。

## 抽样范围

- 仓库数：15（每个仓库选取一个包）
- 许可证：13 个 Apache-2.0，2 个 MIT
- 样本总大小：309,658 字节
- MoonGuard 建模条目：6,700
- 涵盖领域：LLVM/编译器、解析器、异步 HTTP、Web/DOM、Markdown、
  CMark、Python 绑定、属性测试、HTTP 服务、游戏模拟器和知识图谱工具
- 测试命令：`node _build/js/debug/build/cmd/main/main.js inventory-dir <sample-dir> --format json`

## 兼容性矩阵

| 样本 | 建模条目 | unknown | 诊断 | 未限定 `fn`/`impl` | 结论 |
| --- | ---: | ---: | ---: | ---: | --- |
| extism-moonbit-pdk-host | 23 | 0 | 0 | 0 | 通过 |
| mizchi-actrun | 383 | 0 | 0 | 0 | 通过 |
| mizchi-markdown | 180 | 0 | 0 | 0 | 通过 |
| moonbit-community-cmark | 385 | 0 | 0 | 0 | 通过 |
| moonbit-community-moonbitnes | 36 | 0 | 0 | 0 | 通过 |
| moonbit-community-rabbita-dom | 726 | 0 | 0 | 0 | 通过 |
| moonbitlang-async-http | 115 | 0 | 0 | 0 | 通过 |
| moonbitlang-llvm-unsafe | 2,064 | 0 | 0 | 0 | 通过（大接口压力样本） |
| moonbitlang-mbtcc-parser | 542 | 0 | 0 | 0 | 通过 |
| moonbitlang-moonllvm-ir | 1,515 | 0 | 0 | 0 | 通过（大接口压力样本） |
| moonbitlang-python | 157 | 0 | 0 | 119 | 通过（旧式生成格式） |
| moonbitlang-quickcheck | 26 | 0 | 0 | 0 | 通过 |
| oboard-mio | 171 | 0 | 0 | 0 | 通过 |
| oboard-mocket | 257 | 0 | 0 | 0 | 通过 |
| trkbt10-indexion-kgf-types | 239 | 0 | 0 | 0 | 通过 |

“通过”表示命令成功、没有 `unknown` 条目且没有快照诊断；它证明 MoonGuard
能稳定读取并建模这些快照，但不等同于已经覆盖 MoonBit 语法的所有历史版本。

## 结论

15/15 个样本完全落入 MoonGuard 已知声明模型，合计 6,819 个条目，
没有出现未知公共声明或目录诊断。两个最大样本分别产生 2,064 和 1,515 个
条目，说明当前实现不只适用于几十行的人工 fixture，也能处理十万字节级接口。

`moonbitlang/python.mbt` 样本来自较早的生成格式。文件中 public 类型之后存在
119 条不带 `pub` 的 `fn Type::method` 或 `impl Trait for Type` 行。MoonGuard 会在
检测到 `moon info` 生成器标记和 package 声明时启用受限的 legacy 推断，将这些
行作为公开接口建模；该样本因此从 38 个基础条目提升到 157 个完整条目。

## 已知未支持或需谨慎解释的语法

1. **旧式未限定方法与 impl。** 某些历史 `moon info` 输出使用
   `fn Type::method`、`fn[T] Type::method`、`impl Trait for Type`，没有 `pub`
   前缀。MoonGuard 仅在识别到生成器标记与 package 声明时推断其公开性，普通
   源码文本中的未限定声明仍会被忽略。
2. **非公开声明不会进入兼容性模型。** 这是对当前新格式的预期行为，但对于
   历史接口格式，不能仅根据是否存在 `pub` 判断一个成员是否是外部 API。
3. **样本结论是解析兼容性，不是语义等价证明。** MoonGuard 规范化文本签名，
   尚不进行类型别名展开、trait 约束求解或 ABI 级兼容性分析。
4. **生态抽样不是穷举。** 当前样本没有触发 `unknown`，后续遇到新的公开声明
   关键字时，仍应保留为 `unknown` 并新增最小回归 fixture。

后续仍应继续固定不同工具链版本的真实样本，防止生成器标记或旧式声明形态变化
导致 legacy 识别退化。

## 复现

先构建 JS CLI，然后运行：

```powershell
moon run --target js cmd/main -- --help
.\scripts\analyze-real-fixtures.ps1
```

机器可读输出：

```powershell
.\scripts\analyze-real-fixtures.ps1 -Json
```
