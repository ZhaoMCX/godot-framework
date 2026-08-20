# Godot Framework

Godot Framework 是面向 Godot 4.7+ 的轻量运行时架构 addon，提供 Application、Feature、Module、Tool
的显式组合基础和 CQRS 契约。

推荐项目目录使用复数职责名称：

```text
game/
  applications/
  features/
  modules/
  tools/
  arts/
  docs/
```

安装时将 Release ZIP 中的 `addons/godot_framework` 合并到目标 Godot 项目。Framework 不包含需要启用
的 EditorPlugin；等待脚本导入完成后即可使用 `GF` 前缀类型。

当前版本：`0.1.0`，兼容 Godot `4.7.1`。

本仓库从 `ZhaoMCX/godot-framework-legacy@b6cd12b` 建立干净基线。
