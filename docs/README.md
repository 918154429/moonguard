# MoonGuard 评审材料索引

本页是竞赛评审与发布检查的统一入口。项目事实以 README、申报书和验证记录中的
当前数据为准；历史计划仅用于说明设计过程。

## 一页结论

- 定位：MoonBit 公共 API 兼容性与 SemVer 守卫。
- 输入：单个或目录级 `.mbti` / `pkg.generated.mbti` 接口快照。
- 输出：Markdown/JSON 变化报告、`major`/`minor`/`patch` 建议、版本检查和发布计划。
- 验证：默认目标 164/164，JS 目标 165/165。
- 真实样本：15 个公开仓库、6819 个 API 条目、零 `unknown`、零快照诊断。
- 规模：8580 行 `.mbt`，其中非测试代码 5215 行，高于已确认的 4000 行要求。

## 推荐阅读顺序

1. [项目 README](../README.md)：功能、快速开始、CLI 与 CI 示例。
2. [项目申报书](申报书.md)：项目定位、原创性和当前验证结果。
3. [真实 API 演化证据](evidence/README.md)：自举报告和三个外部仓库兼容性报告。
4. [演示与验证记录](demo-report.md)：可复现命令及输出结果。
5. [开发报告](development-report.md)：架构、设计取舍、测试和已知限制。
6. [API 兼容性规则](api-compat-rules.md)：变化分类与保守判定依据。
7. [真实生态兼容性](real-world-compatibility.md)：15 个真实接口样本结果。
8. [生态证据](ecosystem-evidence.md)：MoonBit 包生态需求依据。
9. [GitHub Actions 接入](github-actions.md)：CI 使用方式。
10. [v0.2.0 候选发布说明](release-notes-v0.2.0.md)：当前版本能力与验证摘要。
11. [v0.1.0 历史发布说明](release-notes-v0.1.0.md)：既有 Git 标签对应的历史状态。
12. [包发布清单](package-release.md)：mooncakes 发布状态、风险和操作步骤。

## 材料口径

以下数字应在对外材料中保持一致：

| 项目 | 当前口径 |
| --- | ---: |
| 默认目标测试 | 164/164 |
| JS 目标测试 | 165/165 |
| 全项目覆盖率 | 2383/2808（84.9%） |
| 核心库覆盖率 | 1940/2125（91.3%） |
| 真实仓库样本 | 15 |
| 建模 API 条目 | 6819 |
| unknown / snapshot diagnostics | 0 / 0 |
| `.mbt` 总行数 | 8580 |
| 非测试 `.mbt` 行数 | 5215 |
| 比赛最低要求 | 4000 |

## 交付策略

评审平台是否接受 GIF 或视频附件并不确定，因此项目不依赖媒体演示。评委可以通过
README 中的命令、`demo-report.md` 的固定输出、GitHub Actions 和真实样本记录复现
核心能力。赛前新增交付重点是完成 mooncakes 包发布，使库和 CLI 都具有标准安装入口。
