import 'package:flutter/material.dart';
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
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<TodoModel> _getStartingTasks(List<TodoModel> todos) {
    return todos
        .where((t) => t.startDate != null && _isSameDate(t.startDate!, _selectedDay))
        .toList();
  }

  List<TodoModel> _getDueTasks(List<TodoModel> todos) {
    return todos
        .where((t) => t.dueDate != null && _isSameDate(t.dueDate!, _selectedDay))
        .toList();
  }

  // Returns true if a date has any tasks (for dot markers)
  bool _hasEvents(List<TodoModel> todos, DateTime day) {
    return todos.any((t) =>
    (t.startDate != null && _isSameDate(t.startDate!, day)) ||
        (t.dueDate != null && _isSameDate(t.dueDate!, day)));
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orangeAccent;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Widget _buildTaskTile(TodoModel todo) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: _getPriorityColor(todo.priority),
            width: 5,
          ),
        ),
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: ListTile(
        dense: true,
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          todo.priority.name.toUpperCase(),
          style: TextStyle(
            color: _getPriorityColor(todo.priority),
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<TodoModel> tasks, Color headerColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                title == "Starting" ? Icons.play_circle : Icons.flag,
                color: headerColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: headerColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(color: headerColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              "No tasks",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          )
        else
          ...tasks.map(_buildTaskTile),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        centerTitle: true,
      ),
      body: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          final todos = state is TodoLoaded ? state.todos : <TodoModel>[];
          final startingTasks = _getStartingTasks(todos);
          final dueTasks = _getDueTasks(todos);

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => _isSameDate(day, _selectedDay),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (_hasEvents(todos, day)) {
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 8),
                    _buildSection("Starting", startingTasks, Colors.green),
                    const SizedBox(height: 8),
                    _buildSection("Due", dueTasks, Colors.red),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}