import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:todoappp/core/theme/app_colors.dart';
import 'package:todoappp/model/subtask_model.dart';
import 'package:todoappp/model/task_type.dart';
import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/repository/task_type_repository.dart';
import 'package:todoappp/todo/todo_bloc.dart';

class TaskDetailScreen extends StatefulWidget {
  final TodoModel todo;

  const TaskDetailScreen({super.key, required this.todo});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TodoModel _todo;
  final TextEditingController _subtaskController = TextEditingController();
  final FocusNode _subtaskFocus = FocusNode();
  TaskType? _taskType;
  bool _isAddingSubtask = false;

  @override
  void initState() {
    super.initState();
    _todo = widget.todo;
    _loadTaskType();
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    _subtaskFocus.dispose();
    super.dispose();
  }

  Future<void> _loadTaskType() async {
    if (_todo.taskTypeId == null) return;
    final type = await TaskTypeRepository.getTypeById(_todo.taskTypeId!);
    if (mounted) setState(() => _taskType = type);
  }

  void _saveAndUpdate(TodoModel updated) {
    setState(() => _todo = updated);
    context.read<TodoBloc>().add(UpdateTodoEvent(updatedTodo: updated));
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    final newSubtask = SubTask(id: const Uuid().v4(), title: title);
    final updated = _todo.copyWith(
      subtasks: [..._todo.subtasks, newSubtask],
    );
    _saveAndUpdate(updated);
    _subtaskController.clear();
    HapticFeedback.lightImpact();
  }

  void _toggleSubtask(SubTask subtask) {
    final updatedSubtasks = _todo.subtasks.map((s) {
      if (s.id == subtask.id) {
        return SubTask(id: s.id, title: s.title, isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();
    _saveAndUpdate(_todo.copyWith(subtasks: updatedSubtasks));
    HapticFeedback.selectionClick();
  }

  void _deleteSubtask(SubTask subtask) {
    final updatedSubtasks =
    _todo.subtasks.where((s) => s.id != subtask.id).toList();
    _saveAndUpdate(_todo.copyWith(subtasks: updatedSubtasks));
  }

  void _toggleMainTask() {
    final updated = _todo.copyWith(isCompleted: !_todo.isCompleted);
    _saveAndUpdate(updated);
    context.read<TodoBloc>().add(ToggleTodo(_todo));
  }

  void _showEditDialog() {
    final titleController = TextEditingController(text: _todo.title);
    TaskPriority editPriority = _todo.priority;
    DateTime? editDueDate = _todo.dueDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: AppColors.card(context),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Task',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.title(context))),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: AppColors.title(context)),
                decoration: InputDecoration(
                  hintText: 'Task title',
                  filled: true,
                  fillColor: AppColors.inputFill(context),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: TaskPriority.values.map((p) {
                  final selected = editPriority == p;
                  final color = _priorityColor(p);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setDialog(() => editPriority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? color : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(children: [
                          Icon(_priorityIcon(p),
                              color: selected ? Colors.white : color, size: 18),
                          const SizedBox(height: 2),
                          Text(p.name.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? Colors.white : color)),
                        ]),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: editDueDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked == null) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: editDueDate != null
                        ? TimeOfDay.fromDateTime(editDueDate!)
                        : TimeOfDay.now(),
                  );
                  if (time != null) {
                    setDialog(() => editDueDate = DateTime(picked.year,
                        picked.month, picked.day, time.hour, time.minute));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 16, color: AppColors.greyText(context)),
                    const SizedBox(width: 8),
                    Text(
                      editDueDate == null
                          ? 'Set due date'
                          : _formatDate(editDueDate!),
                      style: TextStyle(
                          color: editDueDate == null
                              ? AppColors.greyText(context)
                              : AppColors.title(context),
                          fontSize: 13),
                    ),
                    const Spacer(),
                    if (editDueDate != null)
                      GestureDetector(
                        onTap: () => setDialog(() => editDueDate = null),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: Colors.red.shade400),
                      ),
                  ]),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                final updated = _todo.copyWith(
                  title: titleController.text.trim(),
                  priority: editPriority,
                  dueDate: editDueDate,
                );
                _saveAndUpdate(updated);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:   return AppColors.danger;
      case TaskPriority.medium: return AppColors.warning;
      case TaskPriority.low:    return AppColors.success;
    }
  }

  IconData _priorityIcon(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:   return Icons.keyboard_double_arrow_up_rounded;
      case TaskPriority.medium: return Icons.drag_handle_rounded;
      case TaskPriority.low:    return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(_todo.priority);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffold(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppColors.title(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Task Detail',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.title(context))),
        actions: [
          IconButton(
            onPressed: _showEditDialog,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.iconBg(context, AppColors.primary),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded,
                  color: AppColors.primary, size: 18),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskHeader(priorityColor),
            const SizedBox(height: 20),
            if (_todo.totalSubtasks > 0) ...[
              _buildProgressCard(),
              const SizedBox(height: 20),
            ],
            _buildSubtasksSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader(Color priorityColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow(context),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _toggleMainTask,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _todo.isCompleted
                        ? AppColors.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _todo.isCompleted
                          ? AppColors.primary
                          : AppColors.checkboxBorder(context),
                      width: 2,
                    ),
                  ),
                  child: _todo.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _todo.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _todo.isCompleted
                        ? AppColors.completedText(context)
                        : AppColors.title(context),
                    decoration: _todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (_taskType != null)
              _badge(_taskType!.icon, _taskType!.name, _taskType!.color),
            _badge(_priorityIcon(_todo.priority),
                _todo.priority.name.toUpperCase(), priorityColor),
            if (_todo.dueDate != null)
              _badge(Icons.calendar_today_rounded,
                  _formatDate(_todo.dueDate!), AppColors.blue),
            if (_todo.startDate != null)
              _badge(Icons.play_circle_outline_rounded,
                  'Start: ${_formatDate(_todo.startDate!)}',
                  AppColors.success),
          ]),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(AppColors.isDark(context) ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _buildProgressCard() {
    final progress = _todo.subtaskProgress;
    final completed = _todo.completedSubtasks;
    final total = _todo.totalSubtasks;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.greyText(context))),
            Text('$completed / $total',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.greyLight(context),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? AppColors.success : AppColors.primary,
            ),
          ),
        ),
        if (progress == 1.0) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 16),
            const SizedBox(width: 6),
            Text('All subtasks completed!',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600)),
          ]),
        ],
      ]),
    );
  }

  Widget _buildSubtasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtasks',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.title(context))),
            GestureDetector(
              onTap: () {
                setState(() => _isAddingSubtask = !_isAddingSubtask);
                if (_isAddingSubtask) {
                  Future.delayed(const Duration(milliseconds: 100),
                          () => _subtaskFocus.requestFocus());
                }
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.iconBg(context, AppColors.primary),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _isAddingSubtask ? Icons.close_rounded : Icons.add_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isAddingSubtask ? 'Cancel' : 'Add',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isAddingSubtask) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(children: [
              const Icon(Icons.radio_button_unchecked_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _subtaskController,
                  focusNode: _subtaskFocus,
                  style: TextStyle(color: AppColors.title(context)),
                  decoration: InputDecoration(
                    hintText: 'Add a subtask...',
                    hintStyle:
                    TextStyle(color: AppColors.greyText(context)),
                    border: InputBorder.none,
                    filled: false,
                  ),
                  onSubmitted: (_) => _addSubtask(),
                  textInputAction: TextInputAction.done,
                ),
              ),
              IconButton(
                onPressed: _addSubtask,
                icon: const Icon(Icons.send_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ]),
          ),
          const SizedBox(height: 12),
        ],

        if (_todo.subtasks.isEmpty && !_isAddingSubtask)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Column(children: [
              Icon(Icons.playlist_add_check_rounded,
                  size: 48,
                  color: AppColors.greyText(context).withOpacity(0.4)),
              const SizedBox(height: 12),
              Text('No subtasks yet',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.greyText(context),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Tap Add to break this task into smaller steps',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.greyText(context).withOpacity(0.7))),
            ]),
          )
        else
          ...List.generate(_todo.subtasks.length, (index) {
            final subtask = _todo.subtasks[index];
            return _buildSubtaskTile(subtask, index);
          }),
      ],
    );
  }

  Widget _buildSubtaskTile(SubTask subtask, int index) {
    return Dismissible(
      key: Key(subtask.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
      ),
      onDismissed: (_) => _deleteSubtask(subtask),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: subtask.isCompleted
              ? AppColors.completedCard(context)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow(context),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => _toggleSubtask(subtask),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: subtask.isCompleted
                    ? AppColors.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: subtask.isCompleted
                      ? AppColors.primary
                      : AppColors.checkboxBorder(context),
                  width: 2,
                ),
              ),
              child: subtask.isCompleted
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtask.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: subtask.isCompleted
                    ? AppColors.completedText(context)
                    : AppColors.title(context),
                decoration: subtask.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: AppColors.completedText(context),
              ),
            ),
          ),
          Icon(Icons.drag_handle_rounded,
              color: AppColors.greyText(context).withOpacity(0.4), size: 18),
        ]),
      ),
    );
  }
}