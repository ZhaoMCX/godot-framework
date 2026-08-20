# Agent 工作规则

本文件只定义仓库共同规则。具体职责、实现约束和验收方式由目标目录最近的 `AGENTS.md` 定义。

## 规则与工作原则

- 修改前从仓库根开始读取目标路径规则链上的全部 `AGENTS.md`；子级规则只能补充或收紧父级规则。
- 新增更深层 `AGENTS.md` 时，从最近父级规则增加入口，保持规则可发现。
- KISS、Agent 友好、显式依赖、职责隔离和可测试性优先于局部便利。
- 修改限制在实际需求和影响范围，不覆盖无关工作或生成内容。

## GF 项目目录

- 项目职责目录统一使用复数：`game/applications`、`game/features`、`game/modules`、`game/tools`、
  `game/arts`、`game/docs`。
- 类名与架构术语保持单数：Application、Feature、Module、Tool。
- 一次游戏运行只能存在一个活动的 Application。`game/applications` 只保存入口脚本、入口场景、
  对应测试和规则文件，不保存业务场景或资源。
- Feature 是完整、用户可感知的功能切片，可以协调零个或多个 Module；例如 `PlayerController` 属于
  Feature。Module 拥有内聚、独立可测试的领域能力和权威状态。
- `game/arts` 只保存纯美术资源，不是运行时架构层；纯美术不得包含业务脚本、碰撞体、物理体或玩法
  状态，也不得反向依赖其他游戏职责。Feature 或 Module 引用纯美术并加入玩法语义后形成的游戏场景
  放回所属职责的 `scenes`。
- `game/tools` 只表示 GF Tool 职责；仓库生成、验证和构建脚本放在仓库根 `tools`。
- 不创建没有实际内容的空职责目录。测试放在所属职责的 `tests` 子目录。

## 通用文件与验证

- 独立职责类单独存放；`PascalCase` 类名映射为 `snake_case.gd` 文件名。
- 资源目录和文件名使用小写 ASCII `snake_case`，场景节点名使用 `PascalCase`。
- `.tres` 使用 `_material.tres`、`_shape.tres` 等下划线语义尾缀。
- 场景编辑期已知的固定 Node 引用必须声明为带具体类型的 `@export var`，并由 `.tscn` 显式绑定；不得
  使用 `get_node`、`get_node_or_null`、`$Node`、`%UniqueNode` 或基于这些路径的 `@onready` 隐式查找。
  只有运行时创建、数量不定、来自外部数据或路径在设计期不可知的 Node 才允许动态解析；动态解析必须
  局部化、验证类型并处理节点不存在的情况。
- 实际行为、分支、不变量和 Bug 回归需要自动化测试；纯文档和资产视觉结果不写行为测试。
- 不提交 `.godot`、`android`、`builds` 和 `reports` 的生成内容，只保留约定的 `.gdignore`。

## 文档、提交与 Godot

- 文档和提交说明以中文为主体；提交采用 `type(scope): 中文摘要`。
- Godot 操作按 Godot AI MCP、Godot CLI、直接文件操作的顺序降级，禁止桌面自动化操作编辑器。
- 创建或修改普通 `.tscn` 后，必须通过 Godot AI MCP 重新打开并显式保存。
- 移动场景或资源后检查并删除空的残留目录。
