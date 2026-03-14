import 'package:flutter/material.dart';
import 'package:todoappp/core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/todo/todo_bloc.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime _focusedDay = DateTime.now();

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<TodoModel> _getStartingTasks(List<TodoModel> todos) {
    return todos
        .where((t) =>
    t.startDate != null && _isSameDate(t.startDate!, _selectedDay))
        .toList();
  }

  List<TodoModel> _getDueTasks(List<TodoModel> todos) {
    return todos
        .where((t) =>
    t.dueDate != null && _isSameDate(t.dueDate!, _selectedDay))
        .toList();
  }

  bool _hasStarting(List<TodoModel> todos, DateTime day) {
    return todos.any((t) => t.startDate != null && _isSameDate(t.startDate!, day));
  }

  bool _hasDue(List<TodoModel> todos, DateTime day) {
    return todos.any((t) => t.dueDate != null && _isSameDate(t.dueDate!, day));
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFEF4444);
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.low:
        return const Color(0xFF10B981);
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Icons.keyboard_double_arrow_up_rounded;
      case TaskPriority.medium:
        return Icons.drag_handle_rounded;
      case TaskPriority.low:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _buildTaskCard(TodoModel todo, {required bool isStarting}) {
    final priorityColor = _getPriorityColor(todo.priority);
    final accentColor = isStarting ? Color(0xFF10B981) : const Color(0xFF6366F1);

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: todo.isCompleted
                            ? AppColors.completedText(context)
                            : AppColors.title(context),
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getPriorityIcon(todo.priority),
                                  size: 10, color: priorityColor),
                              const SizedBox(width: 3),
                              Text(
                                todo.priority.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: priorityColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isStarting
                                    ? Icons.play_circle_outline_rounded
                                    : Icons.schedule_rounded,
                                size: 10,
                                color: accentColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isStarting
                                    ? _formatTime(todo.startDate!)
                                    : _formatTime(todo.dueDate!),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (todo.isCompleted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DONE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, List<TodoModel> tasks, Color headerColor, bool isStarting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: headerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isStarting ? Icons.play_circle_rounded : Icons.flag_rounded,
                color: headerColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.title(context),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: headerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${tasks.length}',
                style: TextStyle(
                  color: headerColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.greyLight(context), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.inbox_rounded, color: AppColors.greyBorder(context), size: 20),
                SizedBox(width: 10),
                Text(
                  'No tasks ${isStarting ? 'starting' : 'due'} today',
                  style: TextStyle(color: AppColors.completedText(context), fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...tasks.map((t) => _buildTaskCard(t, isStarting: isStarting)),
      ],
    );
  }

  String _getSelectedDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (_isSameDate(_selectedDay, today)) return 'Today';
    if (_isSameDate(_selectedDay, tomorrow)) return 'Tomorrow';
    if (_isSameDate(_selectedDay, yesterday)) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_selectedDay.day} ${months[_selectedDay.month - 1]} ${_selectedDay.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inputFill(context),
      appBar: AppBar(
        backgroundColor: AppColors.inputFill(context),
        elevation: 0,
        title: Text(
          'Schedule',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.title(context),
          ),
        ),
      ),
      body: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          final todos = state is TodoLoaded ? state.todos : <TodoModel>[];
          final startingTasks = _getStartingTasks(todos);
          final dueTasks = _getDueTasks(todos);

          return Column(
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2100),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => _isSameDate(day, _selectedDay),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = DateTime(
                          selectedDay.year, selectedDay.month, selectedDay.day);
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final hasStart = _hasStarting(todos, day);
                      final hasDue = _hasDue(todos, day);
                      if (!hasStart && !hasDue) return null;
                      return Positioned(
                        bottom: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasStart)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (hasDue)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6366F1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                    ),
                    selectedTextStyle: TextStyle(
                      color: AppColors.card(context),
                      fontWeight: FontWeight.bold,
                    ),
                    weekendTextStyle: const TextStyle(
                      color: Color(0xFFEF4444),
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.title(context),
                    ),
                    leftChevronIcon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Color(0xFF6366F1), size: 18),
                    ),
                    rightChevronIcon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF6366F1), size: 18),
                    ),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    weekendStyle: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildLegendDot(const Color(0xFF10B981), 'Start date'),
                    const SizedBox(width: 16),
                    _buildLegendDot(const Color(0xFF6366F1), 'Due date'),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getSelectedDateLabel(),
                        style: TextStyle(
                          color: AppColors.card(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      '${startingTasks.length + dueTasks.length} task${startingTasks.length + dueTasks.length != 1 ? 's' : ''}',
                      style: TextStyle(
                          color: AppColors.greyText(context), fontSize: 13),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    _buildSection('Starting', startingTasks,
                        const Color(0xFF10B981), true),
                    const SizedBox(height: 20),
                    _buildSection(
                        'Due', dueTasks, const Color(0xFF6366F1), false),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: AppColors.greyText(context))),
      ],
    );
  }
}