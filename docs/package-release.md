# MoonGuard Mooncakes 发布清单

## 当前状态

截至 2026-07-12，项目已经通过本地打包检查，准备发布到 mooncakes：

- MoonBit 工具链：`moon 0.1.20260608`。
- 模块名：`918154429/moonguard`。
- 模块版本：`0.2.0`。
- `moon package --list` 成功并生成发布包。
- 当前打包检查已通过；加入演化证据并切换到 `0.2.0` 后需重新生成最终发布包。
- 本机 `moon whoami` 已验证为 `918154429`。
- `v0.1.0` 是 GitHub 与 GitLink 上已经存在的历史标签，不能重写。
- 当前公开接口相对 `v0.1.0` 新增 policy 相关类型和函数，MoonGuard 自身的规则应判定为
  `minor` 变化，因此建议首次 mooncakes 发布使用 `0.2.0`。

## 发布前决策

1. 运行 `moon whoami`，确认发布账号为 `918154429`。
2. 确认 `moon.mod` 模块名为 `918154429/moonguard`；首次发布后不再迁移命名空间。
3. 使用 `release-notes-v0.2.0.md`，并在最终发布
   提交上创建新的 `v0.2.0` 标签。禁止让注册中心版本、Git 标签和源码不一致。
4. 在最终发布提交上重新运行全部检查，再同步标签和发布说明。

## 验证命令

```sh
moon fmt
moon info
moon check
moon test
moon test --target js
moon package --list
moon publish --dry-run
```

`moon publish --dry-run` 成功后，再执行真实发布：

```sh
moon publish
```

## 发布后的安装入口

作为库依赖：

```sh
moon add 918154429/moonguard@0.2.0
```

安装 CLI 主包：

```sh
moon install 918154429/moonguard/cmd/main@0.2.0
```

安装后应验证可执行程序名称和 `--help` 输出，再把最终安装命令移到仓库 README 的
Installation 首位。

## 完成标准

- mooncakes 页面可公开访问，元数据、许可证和仓库链接正确。
- 从空目录执行库依赖安装并通过最小调用示例。
- 从空环境安装 CLI，能够完成 `report` 示例。
- Git 标签、`moon.mod` 版本、发布说明和注册中心版本完全一致。
- GitLink 与 GitHub 均同步到同一发布提交。
