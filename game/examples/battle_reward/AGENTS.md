# Battle Reward 框架样例 Agent 规则

本文件补充 `game/AGENTS.md`，仅适用于 Battle Reward 演示子树。

该样例用一个最小的战斗奖励流程展示 Godot Framework 的职责边界：

- `ExampleBattleRewardApplication` 只负责查找节点和注入依赖。
- `ExampleRewardFeature` 协调两个互不依赖的 Module。
- `ExampleBattleModule` 处理击败敌人的 Command，并先发送领域 Event，再发送完成 Event。
- `ExampleScoreModule` 处理加分 Command，并通过隔离的 Snapshot 提供查询结果。
- `ExampleBattleRewardDemo` 是样例入口调用方，不把演示业务写进 Application。

## 运行

在 Godot 编辑器中打开并运行：

```text
res://game/examples/battle_reward/applications/battle_reward_example.tscn
```

输出展示三种结果：

1. 第一次击败敌人：提交被接受，两个 Module 依次完成，最终得分增加。
2. 重复击败同一敌人：提交仍被接受，但 Battle Module 以业务失败完成。
3. 使用非法 Command ID：提交被拒绝，不产生完成 Event。

样例还会修改 Snapshot 返回的数组副本，再次查询确认 Module 内部状态没有被外部修改。

## 依赖方向

```text
Application -> Feature -> Battle Module
                       -> Score Module
```

两个 Module 不互相引用。`ExampleRewardFeature` 监听 `ExampleEnemyDefeatedEvent`，将其转换为
`ExampleAddScoreCommand`。样例没有真实的无状态辅助能力，因此不创建 Tool。

## 测试

Module 和 Feature 的公开行为、分支、事件顺序与 Snapshot 隔离由各职责 `tests` 子目录中的 GDUnit4
测试覆盖；Application 场景保留最小启动验证。演示输出只用于人工运行说明，不替代自动化测试。
