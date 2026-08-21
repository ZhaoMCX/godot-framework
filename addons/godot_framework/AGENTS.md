# Godot Framework Agent 规则

本文件规定框架核心插件子树的开发约束。公开使用方式见 `docs/usage.md`，完整架构见
`docs/architecture.md`，功能插件开发见 `docs/plugin_development.md`，GF 更新流程见 `docs/update.md`。

## 子级规则文件

本文件随 GF 插件发布，在消费项目中作为 `addons/godot_framework` 子树的可分发规则根。

- 只有当插件内的子树存在长期有效、可执行且不适合应用于整个插件范围的独立约束时，才新增更深层
  `AGENTS.md`；不以目录层级、职责名称或当前实现复杂度作为创建理由。
- 子级 `AGENTS.md` 只记录相对本文件新增或收紧的规则，不重复已有内容；架构介绍、运行方式、示例输出、
  当前实现说明和一般开发文档放入 `README.md` 或 `docs`。
- 新增更深层 `AGENTS.md` 时，从最近父级规则增加入口；子树不再具有独立约束时，删除对应规则文件及
  父级入口。

## GF 更新

- 用户提出“更新 GF 插件”“升级 GF 插件”或明确同义请求时，先完整读取 `docs/update.md`，再按其中流程
  准备更新当前项目的 `addons/godot_framework`。更新请求本身不等于覆盖确认；写入前必须列出目标路径、
  当前版本与目标版本，并明确提示旧目录及其中所有本地修改会被永久删除且不创建备份，再询问用户确认。
- 未指定版本时只更新到官方 GitHub Releases 的最新稳定版，忽略草稿和预发布版本；不得自动降级。
- 确认前必须验证官方 Release、SHA-256、归档结构与目标路径，但不检查 Git 状态、不比较或保留插件本地
  修改。用户拒绝时不写入任何项目。
- 用户确认后无备份整目录替换，只保留官方发布包内容，禁止合并覆盖；当前版本等于目标版本时也重装。
  更新只授权替换 GF 插件，不授权修改、提交或推送消费项目代码。替换或验证失败时保留当前结果并报告，
  不自动恢复或修改消费项目代码。

- KISS、Agent 友好、显式组合、模块隔离、CQRS 和可测试性是不可用局部便利换取的核心原则。
- 只为当前明确需求增加抽象；优先 Godot 原生、依赖显式、命名可搜索且可隔离验证的实现。
- 低魔法优先于少写代码，修改一个职责不应要求理解无关模块。
- 本插件的运行时脚本只能位于 `base` 或 `rules`；`tests` 是插件开发内容，不属于运行时发布包。
- `base` 定义架构基础类型，不包含具体游戏层实现。
- CQRS 等跨层契约放在 `rules`，不得放入 Tool。
- 不向核心插件加入具体游戏 Feature、Module、Tool 或业务逻辑。
- 基于 GF 的可复用功能插件可以提供自己的 `Application`、`Feature`、`Module` 和 `Tool`；插件目录只是物理分布，不是额外架构层。完整规则见 `docs/plugin_development.md`。
- 一次运行只能存在一个活动的 Application。Application 只保存入口脚本与入口场景并承担组合，不拥有
  业务场景或资源；测试和规则文件可以与入口同属 `applications`。
- 所有脚本中，场景编辑期已知的固定 Node 引用必须声明为带具体类型的 `@export var`，并由 `.tscn` 的
  `node_paths` 与 NodePath 属性显式绑定。不得用 `get_node`、`get_node_or_null`、`$Node`、`%UniqueNode`
  或基于这些路径的 `@onready` 解析固定节点；测试访问固定场景节点时也使用场景公开的绑定引用。
- 只有运行时创建、数量不定、来自外部数据或路径在设计期不可知的 Node 才允许动态解析。动态解析必须
  保持局部、验证结果类型并处理节点不存在的情况，不得用“动态”规避可由场景表达的依赖。
- Application 场景必须声明并持有需要长期存在的 Module、Feature 或 Feature UI Node，通过类型化导出
  变量显式注入；不得用 `add_child` 或 `PackedScene.instantiate()` 重新创建这些已声明依赖。
- Tool、值对象和无场景所有权的配置辅助对象可以由代码创建；平台实现、适配器、原生 SDK、AAR、EditorExportPlugin 和桌面模拟器按职责归入 Tool，不建立顶层 `runtime`、`adapter` 或 `android_plugin`。
- Feature 是完整、用户可感知的功能切片，可以协调零个或多个 Module，`PlayerController` 属于 Feature；
  Feature 的场景和功能专用资源归属 Feature，由 Application 场景挂载。Feature UI 只调用 Feature 公开
  API，不直接访问 Module 内部或平台桥接。
- Module 拥有内聚、独立可测试的领域能力和权威状态。Feature 或 Module 引用纯美术并添加脚本、碰撞、
  物理或玩法状态后形成的游戏场景，必须放在所属职责的 `scenes`。
- `game/arts` 只保存纯美术，不得包含业务脚本、碰撞体、物理体或玩法状态，也不得反向依赖运行时职责。
- `game/tools` 表示 GF Tool 职责，不得因为内容仅用于开发期就归入该目录；生成、验证和构建等仓库脚本
  使用仓库根 `tools`。
- `GFApplication` 默认在 `_ready()` 组合，此时场景声明的类型化子节点引用已经解析。Feature 和 Module
  不得在自己的 `_ready()` 中使用尚未注入的 Application 依赖；依赖初始化由显式 `configure` 完成。
- 不引用其他职责单元的 `internal` 目录。
- 保持显式组合，不添加 autoload、服务定位器、全局消息总线或反射扫描。
- 每个独立职责类以及每个 Command、Event、Snapshot、API、Adapter、Validator 和测试替身单文件存放。
- Command 通过强类型 API 表达变更意图；Query 返回隔离快照；Signal 只传递 Event。
- 可联网消息只能包含数据值和稳定 ID，不得包含 Object、Node 或 NodePath 身份。
- 重试必须保留 `command_id`，派生 Event 使用 `causation_id` 建立关联。
- 每个已接受 Command 最终只产生一个完成事件，领域事件先于完成事件。
- 测试是 Agent 证明功能正确性的验证证据，不以测试数量或逐文件补测试为目标。功能修改前先识别可观察
  的正确性主张、失败风险和受影响职责，再选择能够直接证明这些主张的最小稳定验证集合。
- Godot 中可确定复现的行为优先使用 GDUnit4。已有测试能够直接证明正确性主张时只需运行，无需重复
  编写；缺少可靠自动化证据时才在所属职责 `tests` 子目录新增或修改测试。Fixture 只属于该职责。
- GDUnit4 按 GF 职责分层：Tool 验证适配、转换、序列化和错误映射；Module 验证领域状态、Command、
  Query、Event 和不变量；Feature 验证跨 Module 协调、流程和事件顺序，不重复 Module 内部断言；
  Application 验证场景绑定、依赖注入、生命周期和最小启动，不承载业务行为测试。
- 公开契约变化沿 `Tool -> Module -> Feature -> Application` 的实际依赖覆盖直接和间接消费者；`base` 或
  `rules` 的变化覆盖实际使用它们的框架与游戏职责。Bug 回归测试放在最早能够稳定观察问题的职责边界；
  多处修改取影响范围并集，边界无法证明时扩大验证范围。
- 带转换、校验、副本隔离或其他逻辑的 getter 视为可执行行为。纯重构、重命名或类型调整且外部可观察
  行为不变时无需改写测试，但必须运行现有相关测试。纯文档、资产视觉结果、无逻辑 getter、Marker 类型、
  静态文件规范和框架尚未执行的设计规定不写行为测试；静态规范和设计规定由规则和架构文档表达。
- 非 Godot 仓库脚本使用对应语言或脚本环境的测试方式，不使用 GDUnit4；真实 SDK、目标设备或视觉结果
  无法由 GDUnit4 可靠证明时使用对应验证方式，并明确未验证风险。
- 功能任务完成时简要说明正确性主张、对应职责层测试、运行结果和未覆盖风险。相关验证失败时不得声明
  完成，除非能够证明失败是既有且与本次修改无关的问题并明确记录。
- 运行时代码不得依赖 GDUnit4、Godot AI 或具体游戏代码。
- 插件文档以中文为主体；提交说明遵循 `type(scope): 中文摘要`。
- 涉及 Godot 编辑器、场景、资源、运行结果或截图时，先判断 Godot AI 是否提供目标操作所需能力。若
  能力满足，必须保证存在可连接且能完成操作的 Godot 编辑器实例并使用 Godot AI MCP。没有可用实例时，
  先按仓库根规则尝试通过 Godot CLI 启动或重启有头或无头编辑器以恢复 MCP；CLI 仅用于引导编辑器，
  不得替代 MCP 完成目标操作。不得因为编辑器未启动、连接失败或服务暂时不可用而降级；恢复尝试失败时
  报告阻塞。只有 Godot AI 不提供所需能力时，才按功能满足情况降级。
