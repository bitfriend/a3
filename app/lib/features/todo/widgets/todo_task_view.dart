import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/models/ToDoList.dart';
import 'package:acter/models/ToDoTask.dart';
import 'package:acter/features/todo/pages/task_detail_page.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ToDoTaskView extends StatefulWidget {
  final ToDoTask task;
  final ToDoList todoList;
  const ToDoTaskView({
    Key? key,
    required this.task,
    required this.todoList,
  }) : super(key: key);

  @override
  State<ToDoTaskView> createState() => _ToDoTaskViewState();
}

class _ToDoTaskViewState extends State<ToDoTaskView> {
  final ToDoController controller = Get.find<ToDoController>();
  late int idx;
  late int listIdx;
  @override
  void initState() {
    super.initState();
    listIdx = controller.todos.indexOf(widget.todoList);
    idx = widget.todoList.tasks.indexOf(widget.task);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(
              index: idx,
              listIndex: listIdx,
            ),
          ),
        );
      },
      child: TaskCard(
        controller: controller,
        task: widget.task,
        todoList: widget.todoList,
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.controller,
    required this.task,
    required this.todoList,
  });
  final ToDoController controller;
  final ToDoTask task;
  final ToDoList todoList;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: InkWell(
                    onTap: () async => await controller
                        .updateToDoTask(task, todoList, null, null, null)
                        .then((res) => debugPrint('TOGGLE CHECK')),
                    child: CircleAvatar(
                      radius: 18,
                      child: Container(
                        height: 25,
                        width: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 1.5,
                          ),
                        ),
                        child: _CheckWidget(task: task),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      task.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: task.progressPercent >= 100
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  child: Visibility(
                    visible: task.progressPercent >= 100,
                    child: const Icon(
                      Atlas.check_circle,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
                task.due != null
                    ? const Icon(Atlas.calendar_dots)
                    : const SizedBox.shrink(),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: task.due != null
                      ? Text(
                          task.progressPercent >= 100
                              ? DateFormat('H:mm E, d MMM')
                                  .format(task.due!.toUtc())
                              : DateFormat('E, d MMM')
                                  .format(task.due!.toUtc()),
                        )
                      : const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Visibility(
                    visible: task.commentsManager.hasComments(),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Atlas.dots_horizontal,
                          color: Colors.grey,
                        ),
                        const Icon(Atlas.message),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${task.commentsManager.commentsCount()}',
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckWidget extends StatelessWidget {
  const _CheckWidget({
    required this.task,
  });

  final ToDoTask task;

  @override
  Widget build(BuildContext context) {
    if ((task.progressPercent < 100)) {
      return const SizedBox.shrink();
    }
    return const Icon(
      Icons.done_outlined,
      size: 14,
    );
  }
}
