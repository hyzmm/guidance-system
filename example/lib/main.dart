import 'dart:convert';

import 'package:example/quest.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:quest_system/quest_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

const routeQ1 = "/routeQ1";
const routeQ2 = "/routeQ2";

void main() {
  QuestSystem.verbose = true;
  // First step: add quest triggers
  QuestSystem.addTrigger(RouteTrigger.instance);
  QuestSystem.addTrigger(CustomTrigger.instance);

  // Second step: add quest to guidance system
  initQuests();

  // Listen change and save data
  // IMPORTANT:
  QuestSystem.listenerAll(() async {
    final sp = await SharedPreferences.getInstance();
    final questData = QuestSystem.acceptVisitor(JsonExportVisitor());
    sp.setString("quest", jsonEncode(questData));
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
      navigatorObservers: [
        RouteTrigger.instance,
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Example"),
      ),
      floatingActionButton: ElevatedButton(
          onPressed: () {
            // Fourth step: trigger some conditions
            CustomTrigger.instance
                .dispatch(const QuestTriggerData(condition: MyQuestId.q2));
          },
          child: const Text("Press me to complete Quest 2")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            buildQ1Box(context),
            buildQ2Box(),
          ],
        ),
      ),
    );
  }

  Widget buildQ1Box(BuildContext context) {
    return Card(
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Quest 1",
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  // Third step: listen to quest status change
                  QuestBuilder<QuestGroup>.id(MyQuestGroupId.group1,
                      builder: (QuestGroup? quest) {
                    return Text(
                        "${quest!.progress}/${quest.length} - ${quest.status.description}");
                  })
                ],
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [MyQuestId.q1, MyQuestId.q2]
                      .map((qId) =>
                          QuestBuilder<Quest>.id(qId, builder: (quest) {
                            return TextButton(
                              onPressed: qId == MyQuestId.q2
                                  ? null
                                  : () {
                                      Get.bottomSheet(
                                          SizedBox(
                                              height: context.heightTransformer(
                                                  dividedBy: 0.6),
                                              child: const Card(
                                                  child: Center(
                                                child: Text(
                                                    "Close this window to complete quest 2"),
                                              ))),
                                          settings: const RouteSettings(
                                              name: routeQ1));
                                    },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(qId.title),
                                  const SizedBox(width: 8),
                                  Text(quest?.status.description ?? "NotFound"),
                                ],
                              ),
                            );
                          }))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildQ2Box() {
    return QuestBuilder<QuestSequence>.id(MyQuestSeqId.seq2, builder: (seq) {
      if (seq == null) return const Text("Quest Not Found");
      if (seq.status == QuestStatus.completed) return const SizedBox();

      return Card(
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Quest Sequence 2",
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  Text("${seq.progress}/${seq.totalProgress}"),
                  Text(seq.status.description),
                ],
              ),

              // Quest.autoTrigger todo
              const SizedBox(height: 8),
              const Text(
                  "I will disappear after completed, Press the button twice to compete the quest sequence."),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () {
                    Get.to(() => const Quest2Page(), routeName: routeQ2);
                  },
                  child: const Text("Press me")),
            ],
          ),
        ),
      );
    });
  }
}

class Quest2Page extends StatefulWidget {
  const Quest2Page({Key? key}) : super(key: key);

  @override
  _Quest2PageState createState() => _Quest2PageState();
}

class _Quest2PageState extends State<Quest2Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quest 2")),
      body: const Center(child: Text("Back to complete quest 2")),
    );
  }
}
