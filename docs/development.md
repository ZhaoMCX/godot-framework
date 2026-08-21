# 开发与发布

本仓库只维护可复用的 Godot Framework 运行时插件及其框架样例。推荐的 GF 项目目录如下：

```text
addons/
  godot_framework/
game/
  applications/
  features/
  modules/
  tools/
  arts/
  docs/
```

`game/applications` 只保存唯一入口的脚本、场景、测试和规则文件，不建立业务 `scenes` 或资源目录。
`game/arts` 用于项目自有或可选复制的纯美术资源；其中内容不得包含业务脚本、碰撞体、物理体或玩法
状态。Feature/Module 引用纯美术并加入业务节点后形成的游戏场景归各自职责目录。插件内部按职责使用
`applications`、`features`、`modules`、`tools`，框架自身的 `base` 与 `rules` 保持不变；仓库自动化脚本
位于根 `tools`，不与 `game/tools` 的 GF Tool 职责混用。

## 验证

在仓库根目录执行发布脚本测试与无界面测试：

```powershell
.\tools\tests\framework_release_scripts_test.ps1
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a addons/godot_framework -a game
```

Godot 可执行文件名称因本机安装方式而异。场景和资源修改仍须遵守对应 `AGENTS.md` 中的 Godot AI MCP
操作规则。

## 准备版本

```powershell
.\tools\prepare_framework_release.ps1 -Version 0.1.2
```

准备脚本要求工作区初始状态干净，只更新 `addons/godot_framework/version.cfg`，并自动完成 Godot 导入、
GDUnit4 测试、打包及产物校验。目标版本等于当前版本时只验证，不修改文件；降级或预发布版本会被拒绝。
本机找不到对应 Godot 可执行文件时使用 `-GodotExecutable <路径>` 显式指定。

脚本生成 `builds/godot-framework-<version>.zip` 及 SHA-256 文件。压缩包根目录固定为
`addons/godot_framework`，不会包含测试、游戏工程、工具缓存或报告。准备完成后提交版本变更并通过 PR
合并；PR 中的 `GF Release` 工作流会重复执行同一套验证。

## 正式发布

版本 PR 合并后，在最新 `master` 提交上创建并推送带注释的版本标签：

```powershell
git switch master
git pull --ff-only
git tag -a v0.1.2 -m "Godot Framework v0.1.2"
git push origin v0.1.2
```

标签必须使用 `v<稳定版 SemVer>`，并与 `version.cfg` 完全一致。GitHub Actions 会从 Godot 官方 Release
下载并校验兼容版本，重新运行测试和打包，先创建草稿 Release，核对 ZIP 与 SHA-256 两个资产后再公开。
标签任务失败时不会公开不完整 Release；修复可重试的问题后重新运行同一任务，不得移动已推送标签。

首个发布版本为 `v0.1.0`；`v0.1.1` 起正式插件包内提供 Agent 更新协议。已发布的标签、ZIP 和校验文件
保持不可变，后续更新必须提升 `version.cfg` 版本并创建新 Release。其他游戏和功能插件通过本地替换
`addons/godot_framework` 后运行各自测试来反馈框架兼容性，不设置跨仓库 CI。
