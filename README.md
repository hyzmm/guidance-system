为 Flutter 实现的任务系统，用于指引用户完成任务，或者新功能介绍 & 指引。假设这些功能在不同的模块的单独编写逻辑，不利于维护和扩展。QuestSystem 可以帮忙以低耦合的方式维护数据，以及提供 Widget 帮助构建 UI。

下面的视频演示了项目中 example 的功能：

https://user-images.githubusercontent.com/48704743/145536738-66f5146c-3e83-4b56-ac6f-b2bcc918e896.mov

QuestSystem 支持这些功能：

- [x] 可中断-恢复的任务
- [x] 任务组
- [x] 串行任务和并行任务
- [x] 任务数据的序列化和反序列化
- [x] 完全分离的代码配置
- [x] 提供 Widget 构建根据任务状态改变的 UI
- [ ] 细化的任务进度，例如「点击按钮 10 次」

最后一个暂不支持的事项是因为目前没有用到这个功能，但是代码上有保留扩展空间。

下面的 UML 图展示了 QuestSystem 的整体结构。

![QuestSystem-UML](https://user-images.githubusercontent.com/48704743/146636720-920e2e9b-e6aa-409a-a7ab-7237906a8d15.png)

从图中可以看到，`QuestSystem` 由以下几个部分组成：

1. QuestSystem：用户入口，通过它配置和访问任务
2. Quest：提供诸如任务、任务组、任务序列等结构体
3. Trigger：任务触发器，触发后开始检查任务
4. QuestChecker：定义如何激活或者完成任务
5. Visitor：规定遍历任务树的方式。例如导入、导出和任务检查就是通过 visitor 进行的
6. Widget：提供 Flutter Widget 组件用于构建与任务相关的 UI

这些模块更复杂的介绍和配置在后面会详细描述。下图展示了 QuestSystem 的工作流程：

![QuestSystem-Flow](https://mermaid.ink/img/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG4gICAgcGFydGljaXBhbnQgUXVlc3RcbiAgICBwYXJ0aWNpcGFudCBUcmlnZ2VyXG4gICAgcGFydGljaXBhbnQgUXVlc3RTeXN0ZW1cbiAgICBwYXJ0aWNpcGFudCBRdWVzdENoZWNrZXJWaXNpdG9yXG4gICAgXG4gICAgTm90ZSBvdmVyIFF1ZXN0U3lzdGVtOiDphY3nva4gUXVlc3Qg5ZKMIFRyaWdnZXJcbiAgICBsb29wIOS7u-WKoeajgOafpVxuICAgICAgICBUcmlnZ2VyIC0-PiBRdWVzdFN5c3RlbTog6Kem5Y-R5qOA5p-l5p2h5Lu2XG4gICAgICAgIFF1ZXN0U3lzdGVtIC0-PiBRdWVzdENoZWNrZXJWaXNvdG9yOiDpgY3ljobku7vliqHmoJFcbiAgICAgICAgYWx0IOS7u-WKoeeKtuaAgeS4uuacqua_gOa0u-S4lOespuWQiOa_gOa0u-adoeS7tlxuICAgICAgICAgICAgUXVlc3RDaGVja2VyVmlzb3RvciAtPj4gUXVlc3Q6IOabtOaUueS7u-WKoeeKtuaAgeS4uua_gOa0u1xuICAgICAgICBlbHNlIOS7u-WKoeeKtuaAgeS4uuW3sua_gOa0u-S4lOespuWQiOWujOaIkOadoeS7tlxuICAgICAgICAgICAgUXVlc3RDaGVja2VyVmlzb3RvciAtPj4gUXVlc3Q6IOabtOaUueS7u-WKoeeKtuaAgeS4uuW3suWujOaIkFxuICAgICAgICBlbmRcbiAgICBlbmRcblxuXG4gICAgICAgICAgICAiLCJtZXJtYWlkIjp7InRoZW1lIjoiZGVmYXVsdCJ9LCJ1cGRhdGVFZGl0b3IiOnRydWUsImF1dG9TeW5jIjp0cnVlLCJ1cGRhdGVEaWFncmFtIjpmYWxzZX0)

### 任务

任务有三个状态（QuestStatus）， 分别是未激活、已激活和已完成，任务的状态切换也是遵循这个顺序。`triggerChecker` 是用来检查能否激活还未激活的任务，`completeChecker` 则用来检查能否完成一个已激活的任务。

配置任务会使用到 Quest、QuestGroup 和 QuestSequnce，通过组合使用它们能够做到复杂的配置。

Quest 用来配置单项任务，表示一个非常具体的任务，不可再细分，它会作为 QuestGroup 或者 QuestSequence 的子节点出现。例如被配置为「点击某个按钮」。

QuestGroup 表示任务组，在任务组未激活的情况下，子任务不会被激活，而在子任务未全部完成的情况下，任务组也无法被完成。任务组和子任务的触发和完成条件都是独立的，不过有时候我们希望任务组激活时，子任务也自动激活，那子任务的触发条件（`triggerChecker`）就可以设置为 `QuestChecker.automate`，为了简化代码，Quest 提供了一个更方便命名构造函数 `Quest.autoTrigger`。另外，如果希望子任务全部完成时，任务组也自动完成，可以把任务组的完成条件（`completeChecker`）设置为 `QuestChecker.automate`。任务组的使用场景可以是完善用户资料这样的任务，因为只有设置完名字、头像等基本信息后才算完善用户资料。

QuestSequnce 是一个串行任务，在前一个任务未完成时，后一个任务不会被检查是否应该激活，而后一个任务也能通过 `QuestChecker.automate` 在前一个任务完成时自动激活。串行任务使用在一个任务必须依赖前置任务已完成的情况下。QuestSequnce 是通过 `QuestSystem.addSequence` 初始化完成的，可以调用多次此接口添加多个串行任务，而多个串行任务允许被同时检查，也就是是配置并行任务的方式。

任务树不能无限的嵌套下去，用户是通过 `QuestSystem.addSequence` 添加任务的  ，参数类型是 `QuestSequnce`，一个包含了所有任务类型的最简化树形结构是：

```
QuestSequence 1
	Quest A
		QuestGroup B
			Quest C
			... More Quest ...
	... More Quest or QuestGroup ...
... QuestSequence ...
```

Quest 模块的结构和组合模式非常接近，QuestSystem 通过语义限定了或者 assert 限制了无限嵌套，主要是因为考虑到多层嵌套对于任务系统来说没有现实意义。

### 触发器

触发器用于通知引导系统开始检查任务，任务状态可能被会检查器（QuestChecker）从未激活切换到已激活，从已激活切换到已完成。有两个内置的触发器：RouteTrigger 和 CustomTrigger，前者通过 Flutter Navigator Observer 自动检查由路由触发的任务条件；后者用于其他需要手动触发的任务条件。在更庞大的业务场景中，可以继承 QuestTrigger 来划分不同的触发器。

### Visitor

Visitor 模块就是使用 Visitor 模式实现的，访问器接口是 QuestNodeVisitor，通过 `QuestSystem.acceptVisitor` 可以接受一个

### ID

无论是 Quest、QuestGroup 还是 QuestSequence 都有一个 id 参数，类型是 Object，这表示它能接受任意参数，不过实际上大多数情况，这个 id 都是一个枚举值。id 的作用是用来获取任务，或者是序列化成数据时用到的，如果不需要这两个功能，甚至可以给 id 传入 `Object()`，实际上 id 的关键是它的 `toString`，在「高级用法」中能看到用 Class 实例作为 id 的情况。

## 使用

添加内置触发器，并且把路由触发器加入到 Navigator Observer 中：

```dart
QuestSystem.addTrigger(RouteTrigger.instance);
QuestSystem.addTrigger(CustomTrigger.instance);

...
MaterialApp(
  navigatorObservers: [
    RouteTrigger.instance,
  ],
)
...
```

配置任务：

```dart
QuestSystem.addSequence(QuestSequence(id: Object(), quests: [
  Quest(...),
  Quest(...),
]));
```

最后使用 `quest.on(...)`  或者 QuestBuilder 使用任务：

```dart
QuestSystem.getQuest(id)!.on((quest) {
  print(quest.status);
});
// or
QuestBuilder<QuestGroup>.id(id,
  builder: (QuestGroup? quest) {
	return Text("${quest!.progress}/${quest.length} - ${quest.status.description}");
})
```

## 用例

创建两条简单的任务序列，在 Q1 完成后，激活 Q2，完成 Q2 后，任务全部完成。

```
QuestSystem.addSequence(QuestSequence(id: Object(), quests: [
  Quest(
    id: QuestId.q1,
    triggerChecker: QuestChecker.condition(QuestCondition.c1),
    completeChecker: QuestChecker.condition(QuestCondition.c2),
  ),
  Quest(
    id: QuestId.q2,
    triggerChecker: QuestChecker.condition(QuestCondition.c1),
    completeChecker: QuestChecker.condition(QuestCondition.c2),
  )
]));
QuestSystem.addSequence(QuestSequence(id: Object(), quests: [
  Quest(
    id: QuestId.q3,
    triggerChecker: QuestChecker.condition(QuestCondition.c1),
    completeChecker: QuestChecker.condition(QuestCondition.c2),
  )
]));
```

2. 
