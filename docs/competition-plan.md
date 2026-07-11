# MoonGuard Competition Plan

本文档是新的参赛推进计划。原 Markdown-to-HTML 方向不再作为主线推进，现转向更贴近 MoonBit 生态缺口的项目：

> MoonGuard：MoonBit 公共 API 兼容性与语义版本检查工具。

## 核心判断

Markdown-to-HTML 工具容易与现有文档、静态站点、Markdown 解析项目重叠，且要做出 4k-10k 行规模和鲜明生态价值，需要扩展到文档发布、代码块验证、API 文档生成等复合方向，边界会变宽。

MoonGuard 的口子更窄，但生态价值更直接：MoonBit 包生态增长后，库作者需要知道一次改动是否破坏公共 API，使用者也需要在 CI 中阻止不兼容升级。当前 MoonBit 已能生成 `pkg.generated.mbti` 这类接口文件，但生态中缺少围绕接口文件做自动兼容性检查、SemVer 建议和发布报告的工具。

## 项目定位

MoonGuard 是一个面向 MoonBit 库作者和生态维护者的公共 API 守卫工具。它读取两个版本的 MoonBit 接口描述，解析公共 API，生成结构化差异，并判断本次变更属于 breaking、minor 还是 patch。

目标用户：

- MoonBit 开源库作者：发布前确认是否破坏 API。
- 包维护者：在 PR 中自动检查公共接口变化。
- 竞赛评审和生态使用者：快速理解一个库的 API 演进。
- 后续包管理、发布、文档工具：复用 MoonGuard 的接口模型和 diff 能力。

一句话说明：

> MoonGuard compares MoonBit public interfaces and turns API changes into actionable compatibility reports.

## 为什么值得做

MoonBit 生态目前更缺少工程基础设施，而不仅是单个功能库。公共 API 兼容性检查具备以下价值：

- 直接服务 MoonBit 包生态，和语言特性、接口文件、CI 流程紧密相关。
- 适合作为独立 CLI，也适合作为库被其他工具复用。
- 可以形成清晰的测试矩阵：解析 fixtures、diff golden tests、SemVer 规则测试、报告格式测试。
- 工程边界清楚，不需要实现完整编译器，也不依赖大型运行时。
- 与已有 MoonBit 项目重合度低，竞争压力小，展示时容易说明生态缺口。

## 参赛仓库策略

当前仓库：

- GitHub：`https://github.com/918154429/moonguard`

仓库已按新方向改名为 `moonguard`。

原因：

- 避免项目名称与旧 Markdown 方向不匹配。
- 保持申报材料、README、CI、提交历史围绕同一目标。
- 不与 `918154429/openvela-smarthome-agent` 的应用方向重合。
- GitLink 可由 GitHub 同步，主维护对象保持 GitHub 仓库即可。

早期 Markdown 实验只作为历史提交存在，不作为最终申报主线。

## 核心功能范围

第一版必须完成的能力：

- 读取两个 `.mbti` 或 `pkg.generated.mbti` 文件。
- 解析 MoonBit 公共接口中的核心声明：
  - public value / function
  - public type
  - public type alias
  - public enum / constructor
  - public struct / field
  - public trait
  - public method
  - error type
- 建立规范化 API 模型，消除格式差异对比较结果的影响。
- 对两个版本的 API 模型进行 diff。
- 将变更分为：
  - breaking：删除公共符号、修改函数签名、收窄类型能力、删除构造器或字段等。
  - minor：新增公共符号、新增兼容能力。
  - patch：无公共 API 变化或仅报告文本变化。
- 输出 SemVer 建议：
  - breaking -> major
  - only additions -> minor
  - no public change -> patch
- 提供 CLI：
  - `moonguard diff old.mbti new.mbti`
  - `moonguard check old.mbti new.mbti --current 0.1.0 --next 0.2.0`
  - `moonguard report old.mbti new.mbti --format markdown`
  - `moonguard report old.mbti new.mbti --format json`
- 提供 CI 用法示例，用于 PR 检查和发布前检查。

增强功能：

- 支持 package 级别目录比较，而不是单文件比较。
- 支持 baseline 文件，便于库作者固定上一个发布版本。
- 支持忽略规则，例如允许某个实验 API 破坏兼容。
- 支持 Markdown 报告，直接贴到 PR 或 release note。
- 支持 JSON 报告，供后续工具链消费。
- 支持从 `moon info` / `moon check` 产物中定位接口文件。

## 非目标

MoonGuard 第一阶段不做以下事情：

- 不实现完整 MoonBit 编译器或类型检查器。
- 不判断函数行为语义是否兼容。
- 不比较私有实现细节。
- 不保证覆盖 MoonBit 语言所有边角语法，先覆盖真实库中高频公共接口形态。
- 不直接替代包管理器，只提供兼容性检查和报告能力。

## 技术设计

建议模块结构：

```text
src/
  lexer/        # mbti tokenization
  parser/       # interface parser
  model/        # normalized API model
  diff/         # public API diff engine
  semver/       # version and compatibility rules
  report/       # text, markdown, json reports
  cli/          # command dispatch and file IO
test/
  fixtures/     # old/new mbti examples
  golden/       # expected reports
docs/
  competition-plan.md
  development-report.md
  api-compat-rules.md
```

核心数据流：

```text
old.mbti -> lexer -> parser -> API model \
                                           -> diff -> severity -> report -> CI exit code
new.mbti -> lexer -> parser -> API model /
```

CLI 退出码建议：

- `0`：检查通过。
- `1`：发现 breaking change 或 SemVer 不满足要求。
- `2`：输入文件、解析或配置错误。

## 兼容性规则草案

初始规则应保守，宁可把有风险的变化标为 breaking，也不要误报为兼容。

Breaking changes：

- 删除 public function / value。
- 修改 public function 的参数数量、参数类型或返回类型。
- 删除 public type、trait、constructor、method。
- 删除 public struct field。
- 将可构造类型改为不可构造。
- 改变 type alias 指向。
- 改变 error 类型的公开形态。

Minor changes：

- 新增 public function / value。
- 新增 public type、trait、constructor、method。
- 新增 public struct field，前提是不会破坏构造兼容性。
- 新增文档可见的能力但不改变已有签名。

Patch changes：

- 公共 API 模型无变化。
- 仅格式、注释、声明顺序发生变化。

需要在文档中明确：规则会随着 MoonBit 接口格式和生态实践迭代。

## 测试计划

测试必须成为项目亮点，而不是附属品。

必备测试：

- lexer 单元测试：关键 token、字符串、泛型、箭头、括号。
- parser 单元测试：函数、类型、trait、method、enum、struct。
- model normalization 测试：声明顺序变化不影响 diff。
- diff 测试：新增、删除、修改、重命名、复杂签名变化。
- SemVer 测试：当前版本和目标版本是否匹配 diff 等级。
- golden report 测试：Markdown / JSON 输出稳定。
- CLI 测试：正常输出、失败退出码、错误输入。

建议使用真实 MoonBit 包生成的 `.mbti` 作为 fixtures，但需要注意许可证和来源记录。

## 文档交付

最终仓库至少包含：

- `README.md`
  - 项目目标
  - 安装方式
  - 快速开始
  - CLI 示例
  - CI 示例
  - 兼容性规则摘要
- `docs/api-compat-rules.md`
  - 详细规则和例子
- `docs/development-report.md`
  - 开发过程
  - 设计取舍
  - AI 协作记录
  - 测试结果
  - 已知限制
- `.github/workflows/ci.yml`
  - format
  - check
  - build
  - test

## 阶段计划

### Phase 0：立项切换

目标：完成仓库和代码主线切换到 `moonguard`。

任务：

- 新建 GitHub 仓库。
- 初始化 MoonBit 项目。
- 写入 README、competition plan、development report 初稿。
- 设置 GitHub Actions。
- 保持 10-20 次有效提交，不通过空提交凑数。

### Phase 1：接口解析最小闭环

目标：能解析真实 `.mbti` 文件中的基础公共声明。

任务：

- 实现 lexer。
- 实现 parser。
- 定义 API model。
- 加入基础 fixtures。
- 通过 parser 测试。

验收标准：

- 对至少 10 个不同形态的 `.mbti` fixtures 解析成功。
- 解析结果可以稳定 pretty print 或 JSON 化。

### Phase 2：Diff 与 SemVer

目标：把接口差异变成可执行的兼容性结论。

任务：

- 实现 diff engine。
- 实现 breaking / minor / patch 分类。
- 实现 SemVer 检查。
- 实现 CLI `diff` 和 `check`。

验收标准：

- 删除函数能被标记为 breaking。
- 修改签名能被标记为 breaking。
- 新增函数能被标记为 minor。
- 无公共变化能被标记为 patch。
- CLI exit code 可用于 CI。

### Phase 3：报告与 CI 集成

目标：让工具具备真实开源项目可用性。

任务：

- 实现 Markdown report。
- 实现 JSON report。
- 加入 GitHub Actions 示例。
- 编写使用文档。
- 补充 golden tests。

验收标准：

- 报告能清楚列出符号、变更类型、严重程度和建议版本。
- JSON 输出稳定，适合后续工具消费。
- README 中的示例可复现。

### Phase 4：竞赛材料收束

目标：完成申报和验收材料。

任务：

- [x] 补齐 README。
- [x] 补齐 development report。
- [x] 整理 commits。
- [x] 配置并运行 CI 验证流程。
- [ ] 准备一页项目申报 PDF。
- [x] 连接并同步 GitLink；2026-07-10 核对时，GitHub 与 GitLink 的
  `master` 均指向 `2faa99cdcb9753200e14c2d9f6b39daf6622a8d7`。

验收标准：

- GitHub 公开可访问。
- CI 通过。
- 测试覆盖核心路径。
- README 能让评审在 5 分钟内理解价值并跑通示例。

## 申报书摘要草案

项目名称：

MoonGuard：MoonBit 公共 API 兼容性与语义版本检查工具

项目方向：

MoonBit 工程基础设施 / 包生态质量工具

项目简介：

MoonGuard 面向 MoonBit 开源库作者，提供公共 API diff、兼容性检查和 SemVer 建议能力。项目读取 MoonBit 生成的接口文件，解析公共声明，构建规范化 API 模型，对比两个版本之间的变化，并输出 breaking、minor、patch 等级判断。工具可作为命令行程序接入 GitHub Actions，也可作为库被后续文档、发布和包管理工具复用。

核心功能：

- `.mbti` 接口文件解析。
- MoonBit 公共 API 模型。
- API diff 引擎。
- breaking / minor / patch 分类。
- SemVer 检查。
- Markdown / JSON 报告。
- CI 集成示例。
- fixtures、golden tests 和开发报告。

原创性说明：

本项目为原创 MoonBit 工程基础设施工具，参考 Rust `cargo-semver-checks`、Go `apidiff`、TypeScript API Extractor 等成熟生态经验，但不直接移植其代码。MoonGuard 会围绕 MoonBit 接口文件、MoonBit 类型系统和 MoonBit 工具链重新设计数据模型、兼容性规则和 CLI 工作流。

参考项目：

- Rust `cargo-semver-checks`：`https://github.com/obi1kenobi/cargo-semver-checks`
- Go `apidiff`：`https://pkg.go.dev/golang.org/x/exp/apidiff`
- TypeScript API Extractor：`https://api-extractor.com/`

许可证建议：

- Apache-2.0 或 MIT。

## 风险与对策

风险：`.mbti` 格式可能变化。

对策：将 parser 和 model 分层，fixtures 固定版本，并在 README 中声明支持的 MoonBit toolchain 版本。

风险：MoonBit 语法覆盖不完整。

对策：先支持真实库中高频公共声明，未支持语法给出明确诊断；通过 fixtures 持续扩大覆盖面。

风险：兼容性规则存在争议。

对策：采用保守规则，文档列明每条规则的判断依据，并允许后续通过配置降低或忽略某些规则。

风险：项目规模不足。

对策：围绕 lexer、parser、model、diff、report、CLI、测试 fixtures 展开，形成真实工程体量，而不是堆功能。

风险：申报时间紧。

对策：优先做最小闭环：解析 -> diff -> SemVer -> Markdown report -> CI。增强功能延后，不影响主线验收。

## 当前最需要用户帮助的事项

- 最终仓库名已确认为 `moonguard`。
- 许可证已确认为 Apache-2.0。
- 提供报名表中需要的人名、联系方式等个人信息。
- 准备并确认最终提交用的一页项目申报 PDF。
- GitHub 为主维护仓库，GitLink 已连接并保持同步。

## 最终交付定义

最终作品应达到以下状态：

- 一个独立公开 GitHub 仓库。
- MoonBit 为主要实现语言。
- 能在本地和 CI 中完成 format、check、build、test。
- CLI 可运行并能输出有用的 API 兼容性报告。
- README、规则文档、开发报告齐全。
- 有足够 fixtures 和 golden tests 支撑评审复现。
- 项目定位清晰：MoonBit 包生态的公共 API 兼容性守卫工具。
