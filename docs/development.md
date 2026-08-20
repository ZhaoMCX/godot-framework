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

`game/arts` 用于项目自有或可选复制的美术资源；框架运行时代码不得依赖其中内容。插件内部按职责使用
`applications`、`features`、`modules`、`tools`，框架自身的 `base` 与 `rules` 保持不变。

## 验证

在仓库根目录执行无界面测试：

```powershell
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a addons/godot_framework/tests -a game/tests
```

Godot 可执行文件名称因本机安装方式而异。场景和资源修改仍须遵守对应 `AGENTS.md` 中的 Godot AI MCP
操作规则。

## 打包

```powershell
.\tools\package_framework.ps1
```

脚本从 `addons/godot_framework/version.cfg` 读取版本，生成
`builds/godot-framework-<version>.zip` 及 SHA-256 文件。压缩包根目录固定为
`addons/godot_framework`，不会包含测试、游戏工程、工具缓存或报告。

当前首个发布版本为 `v0.1.0`。其他游戏和功能插件通过本地替换
`addons/godot_framework` 后运行各自测试来反馈框架兼容性，不设置跨仓库 CI。
