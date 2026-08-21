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

一次运行只有一个 Application，它只承担入口组合。Feature 表示完整的用户功能并可协调零个或多个
Module；Module 拥有内聚领域能力。`game/arts` 只保存不含脚本、碰撞、物理和玩法状态的纯美术，
Feature/Module 引用美术并加入业务节点后形成的场景归各自 `scenes`。`game/tools` 是 GF Tool 职责，
仓库级生成、验证和构建脚本使用根目录 `tools`。

首次安装时将 Release ZIP 中的 `addons/godot_framework` 放入目标 Godot 项目。升级时必须整目录替换，
不得合并覆盖。Framework 不包含需要启用的 EditorPlugin；等待脚本导入完成后即可使用 `GF` 前缀类型。

当前版本与 Godot 兼容版本以插件内的 [`version.cfg`](addons/godot_framework/version.cfg) 为准。
从 `v0.1.1` 开始，插件内提供面向编码 Agent 的
[一句话更新协议](addons/godot_framework/docs/update.md)。

本仓库从 `ZhaoMCX/godot-framework-legacy@b6cd12b` 建立干净基线。
