import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todoappp/core/services/streak_services.dart';
import 'package:todoappp/core/theme/app_colors.dart';
import 'package:todoappp/enum.dart';
import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/model/task_type.dart';
import 'package:todoappp/repository/task_type_repository.dart';
import 'package:todoappp/screens/stats_screen.dart';
import 'package:todoappp/screens/task_detail_screen.dart';
import 'package:todoappp/todo/todo_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TaskFilter selectedFilter = TaskFilter.all;
  String? selectedTypeId;
  List<TaskType> _allTaskTypes = [];
  StreakData? _streakData;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _dismissedIds = {};

  @override
  void initState() {
    super.initState();
    context.read<TodoBloc>().add(LoadTodos());
    _loadTaskTypes();
    _loadStreak();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStreak() async {
    final data = await StreakService.getStreakData();
    if (mounted) setState(() => _streakData = data);
  }
  Future<void> _loadTaskTypes() async {
    final types = await TaskTypeRepository.getAllTypes();
    if (mounted) setState(() => _allTaskTypes = types);
  }
  TaskType? _getTaskType(String? id) {
    if (id == null) return null;
    try {
      return _allTaskTypes.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
  Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:   return const Color(0xFFEF4444);
      case TaskPriority.medium: return const Color(0xFFF59E0B);
      case TaskPriority.low:    return const Color(0xFF10B981);
    }
  }
  IconData getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:   return Icons.keyboard_double_arrow_up_rounded;
      case TaskPriority.medium: return Icons.drag_handle_rounded;
      case TaskPriority.low:    return Icons.keyboard_double_arrow_down_rounded;
    }
  }
  List<TodoModel> applyFilterAndSort(List<TodoModel> todos) {
    final now = DateTime.now();
    List<TodoModel> filtered = todos.where((todo) {
      if (_searchQuery.isNotEmpty) {
        return todo.title.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      final passesStatus = () {
        switch (selectedFilter) {
          case TaskFilter.overdue:
            return todo.dueDate != null && !todo.isCompleted && todo.dueDate!.isBefore(now);
          case TaskFilter.completed:
            return todo.isCompleted;
          case TaskFilter.highPriority:
            return todo.priority == TaskPriority.high;
          case TaskFilter.all:
          default:
            return true;
        }
      }();
      final passesType = selectedTypeId == null || todo.taskTypeId == selectedTypeId;
      return passesStatus && passesType;
    }).toList();
    filtered.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      bool aOverdue = a.dueDate != null && !a.isCompleted && a.dueDate!.isBefore(now);
      bool bOverdue = b.dueDate != null && !b.isCompleted && b.dueDate!.isBefore(now);
      if (aOverdue && !bOverdue) return -1;
      if (!aOverdue && bOverdue) return 1;
      if (a.dueDate != null && b.dueDate != null) {
        int dateCompare = a.dueDate!.compareTo(b.dueDate!);
        if (dateCompare != 0) return dateCompare;
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      return a.priority.index.compareTo(b.priority.index);
    });
    return filtered;
  }
  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TodoBloc>(),
        child: _AddTaskSheet(
          allTaskTypes: _allTaskTypes,
          onTypeAdded: _loadTaskTypes,
        ),
      ),
    );
  }
  void _showEditDialog(TodoModel todo) {
    final TextEditingController editingController = TextEditingController(text: todo.title);
    TaskPriority editPriority = todo.priority;
    DateTime? editDueDate = todo.dueDate;
    String? editTaskTypeId = todo.taskTypeId;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (innerContext, setStateDialog) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.edit_rounded, color: Color(0xFF6366F1), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('Edit Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 20),
                      TextField(
                        controller: editingController,
                        decoration: InputDecoration(
                          hintText: 'Task title', filled: true,
                          fillColor: AppColors.inputFill(context),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Task Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.greyText(context))),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 76,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _allTaskTypes.length,
                          itemBuilder: (_, index) {
                            final type = _allTaskTypes[index];
                            final selected = editTaskTypeId == type.id;
                            return GestureDetector(
                              onTap: () => setStateDialog(() => editTaskTypeId = selected ? null : type.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? type.color : type.color.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: selected ? type.color : type.color.withOpacity(0.2)),
                                ),
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(type.icon, color: selected ? Colors.white : type.color, size: 20),
                                  const SizedBox(height: 4),
                                  Text(type.name, style: TextStyle(fontSize: 10, color: selected ? Colors.white : type.color, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: TaskPriority.values.map((priority) {
                          final isSelected = editPriority == priority;
                          final color = getPriorityColor(priority);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setStateDialog(() => editPriority = priority),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(color: isSelected ? color : color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Column(children: [
                                  Icon(getPriorityIcon(priority), color: isSelected ? Colors.white : color, size: 18),
                                  const SizedBox(height: 2),
                                  Text(priority.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color)),
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
                            context: context, useRootNavigator: true,
                            initialDate: editDueDate ?? DateTime.now(),
                            firstDate: DateTime(2000), lastDate: DateTime(2100),
                          );
                          if (picked == null) return;
                          final pickedTime = await showTimePicker(
                            context: context, useRootNavigator: true,
                            initialTime: editDueDate != null ? TimeOfDay.fromDateTime(editDueDate!) : TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setStateDialog(() {
                              editDueDate = DateTime(picked.year, picked.month, picked.day, pickedTime.hour, pickedTime.minute);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: AppColors.greyLight(context), borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.greyText(context)),
                            const SizedBox(width: 8),
                            Text(
                              editDueDate == null ? 'Set due date' : '${editDueDate!.day}/${editDueDate!.month}/${editDueDate!.year}  ${editDueDate!.hour.toString().padLeft(2, '0')}:${editDueDate!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(color: editDueDate == null ? AppColors.greyText(context) : AppColors.title(context), fontSize: 13),
                            ),
                            const Spacer(),
                            if (editDueDate != null)
                              GestureDetector(
                                onTap: () => setStateDialog(() => editDueDate = null),
                                child: Icon(Icons.close_rounded, size: 16, color: Colors.red.shade400),
                              ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final updatedTodo = TodoModel(
                                id: todo.id, title: editingController.text,
                                isCompleted: todo.isCompleted, priority: editPriority,
                                dueDate: editDueDate, startDate: todo.startDate,
                                taskTypeId: editTaskTypeId, subtasks: todo.subtasks,
                              );
                              context.read<TodoBloc>().add(UpdateTodoEvent(updatedTodo: updatedTodo));
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ]),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  bool get _hasActiveFilters => selectedFilter != TaskFilter.all || selectedTypeId != null;

  String _activeFilterLabel() {
    final parts = <String>[];
    if (selectedFilter != TaskFilter.all) {
      const labels = {
        TaskFilter.overdue: 'Overdue', TaskFilter.completed: 'Completed',
        TaskFilter.highPriority: 'High Priority', TaskFilter.all: 'All',
      };
      parts.add(labels[selectedFilter]!);
    }
    if (selectedTypeId != null) {
      final type = _getTaskType(selectedTypeId);
      if (type != null) parts.add(type.name);
    }
    return 'Filtered: ${parts.join(' · ')}';
  }

  void _showFilterSheet(List<TodoModel> todos) {
    final usedTypeIds = todos.map((t) => t.taskTypeId).whereType<String>().toSet();
    final visibleTypes = _allTaskTypes.where((t) => usedTypeIds.contains(t.id)).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.greyBorder(context), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Text('Filter Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.title(context))),
                  const Spacer(),
                  if (_hasActiveFilters)
                    TextButton(
                      onPressed: () {
                        setState(() { selectedFilter = TaskFilter.all; selectedTypeId = null; });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear all', style: TextStyle(color: Color(0xFF6366F1))),
                    ),
                ]),
                const SizedBox(height: 20),
                Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.greyText(context), letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: TaskFilter.values.map((filter) {
                    final isSelected = selectedFilter == filter;
                    final labels = { TaskFilter.all: 'All', TaskFilter.overdue: 'Overdue', TaskFilter.completed: 'Completed', TaskFilter.highPriority: 'High Priority' };
                    final icons = { TaskFilter.all: Icons.list_rounded, TaskFilter.overdue: Icons.warning_amber_rounded, TaskFilter.completed: Icons.check_circle_rounded, TaskFilter.highPriority: Icons.keyboard_double_arrow_up_rounded };
                    return GestureDetector(
                      onTap: () { setState(() => selectedFilter = filter); setSheetState(() {}); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF6366F1) : AppColors.greyLight(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(icons[filter], size: 14, color: isSelected ? Colors.white : AppColors.greyText(context)),
                          const SizedBox(width: 6),
                          Text(labels[filter]!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.greyText(context))),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                if (visibleTypes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Task Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.greyText(context), letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      GestureDetector(
                        onTap: () { setState(() => selectedTypeId = null); setSheetState(() {}); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selectedTypeId == null ? AppColors.title(context) : AppColors.greyLight(context),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('All Types', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selectedTypeId == null ? AppColors.card(context) : AppColors.greyText(context))),
                        ),
                      ),
                      ...visibleTypes.map((type) {
                        final isSelected = selectedTypeId == type.id;
                        return GestureDetector(
                          onTap: () { setState(() => selectedTypeId = isSelected ? null : type.id); setSheetState(() {}); },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: isSelected ? type.color : AppColors.greyLight(context), borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(type.icon, size: 14, color: isSelected ? Colors.white : type.color),
                              const SizedBox(width: 6),
                              Text(type.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.greyText(context))),
                            ]),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffold(context),
        elevation: 0,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: AppColors.title(context), fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search tasks...',
            hintStyle: TextStyle(color: AppColors.greyText(context)),
            border: InputBorder.none, filled: false,
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGreeting(), style: TextStyle(fontSize: 13, color: AppColors.greyText(context), fontWeight: FontWeight.w400)),
            Text('My Tasks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.title(context))),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) { _searchQuery = ''; _searchController.clear(); }
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isSearching ? AppColors.primary : AppColors.iconBg(context, AppColors.primary),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: _isSearching ? Colors.white : AppColors.primary, size: 20),
            ),
          ),
          if (!_isSearching) ...[
            BlocBuilder<TodoBloc, TodoState>(
              builder: (context, state) {
                final todos = state is TodoLoaded ? state.todos : <TodoModel>[];
                return IconButton(
                  onPressed: () => _showFilterSheet(todos),
                  icon: Stack(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _hasActiveFilters ? const Color(0xFF6366F1) : AppColors.iconBg(context, const Color(0xFF6366F1)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.tune_rounded, color: _hasActiveFilters ? Colors.white : const Color(0xFF6366F1), size: 20),
                    ),
                    if (_hasActiveFilters)
                      Positioned(top: 0, right: 0, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle))),
                  ]),
                );
              },
            ),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF6366F1), size: 20),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          BlocBuilder<TodoBloc, TodoState>(
            builder: (context, state) {
              if (state is TodoLoaded) {
                final total = state.todos.length;
                final completed = state.todos.where((t) => t.isCompleted).length;
                final now = DateTime.now();
                final overdue = state.todos.where((t) => t.dueDate != null && !t.isCompleted && t.dueDate!.isBefore(now)).length;
                WidgetsBinding.instance.addPostFrameCallback((_) => _loadStreak());
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(children: [
                    Row(children: [
                      _buildMiniStat('Total', total.toString(), const Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      _buildMiniStat('Done', completed.toString(), const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _buildMiniStat('Overdue', overdue.toString(), const Color(0xFFEF4444)),
                    ]),
                    if (_streakData != null) ...[const SizedBox(height: 8), _buildStreakBar()],
                  ]),
                );
              }
              return const SizedBox();
            },
          ),
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(children: [
                const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Expanded(child: Text(_activeFilterLabel(), style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w500))),
                GestureDetector(
                  onTap: () => setState(() { selectedFilter = TaskFilter.all; selectedTypeId = null; }),
                  child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF6366F1)),
                ),
              ]),
            ),
          Expanded(
            child: BlocBuilder<TodoBloc, TodoState>(
              builder: (context, state) {
                if (state is TodoLoaded) {
                  final filteredTodos = applyFilterAndSort(state.todos)
                      .where((t) => !_dismissedIds.contains(t.id))
                      .toList();
                  if (filteredTodos.isEmpty) return _buildEmptyState();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: filteredTodos.length,
                    itemBuilder: (context, index) => _buildTaskCard(filteredTodos[index]),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: _showAddTaskSheet,
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(color: color.withOpacity(AppColors.isDark(context) ? 0.15 : 0.08), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
        ]),
      ),
    );
  }

  Widget _buildStreakBar() {
    final streak = _streakData!;
    final isActive = streak.currentStreak > 0;
    final color = isActive ? const Color(0xFFF59E0B) : AppColors.greyText(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF59E0B).withOpacity(AppColors.isDark(context) ? 0.2 : 0.1) : AppColors.greyLight(context),
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)) : null,
      ),
      child: Row(children: [
        Text(streak.streakEmoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isActive ? '${streak.currentStreak} day streak!' : 'No active streak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          Text(streak.streakMessage, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Best: ${streak.bestStreak}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          Text('${streak.totalCompleted} done', style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
        ]),
      ]),
    );
  }

  Widget _buildTaskCard(TodoModel todo) {
    final now = DateTime.now();
    final isOverdue = todo.dueDate != null && !todo.isCompleted && todo.dueDate!.isBefore(now);
    final priorityColor = getPriorityColor(todo.priority);
    final taskType = _getTaskType(todo.taskTypeId);
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        final bloc = context.read<TodoBloc>();
        final messenger = ScaffoldMessenger.of(context);
        setState(() => _dismissedIds.add(todo.id));
        bloc.add(DeleteTodo(todo.id));
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Task deleted', style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF1E1B4B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: const Color(0xFF6366F1),
              onPressed: () {
                setState(() => _dismissedIds.remove(todo.id));
                bloc.add(AddTodoModel(todo));
              },
            ),
          ),
        );
        return true;
      },
      onDismissed: (_) {},
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(value: context.read<TodoBloc>(), child: TaskDetailScreen(todo: todo)),
          ),
        ).then((_) => context.read<TodoBloc>().add(LoadTodos())),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: todo.isCompleted ? AppColors.completedCard(context) : AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: IntrinsicHeight(
            child: Row(children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: todo.isCompleted ? AppColors.greyBorder(context) : priorityColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: todo.isCompleted,
                    onChanged: (_) => context.read<TodoBloc>().add(ToggleTodo(todo)),
                    activeColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    side: BorderSide(color: AppColors.greyBorder(context), width: 1.5),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: todo.isCompleted ? AppColors.completedText(context) : AppColors.title(context),
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.completedText(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if (taskType != null) _buildBadge(icon: taskType.icon, label: taskType.name, color: taskType.color),
                      _buildBadge(icon: getPriorityIcon(todo.priority), label: todo.priority.name.toUpperCase(), color: priorityColor),
                      if (todo.dueDate != null) _buildBadge(icon: isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded, label: _formatDate(todo.dueDate!), color: isOverdue ? Colors.red : Colors.blue),
                    ]),
                    if (todo.startDate != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.play_circle_outline_rounded, size: 11, color: Colors.green.shade600),
                        const SizedBox(width: 3),
                        Text('Start: ${_formatDate(todo.startDate!)}', style: TextStyle(fontSize: 10, color: Colors.green.shade600, fontWeight: FontWeight.w500)),
                      ]),
                    ],
                    if (todo.totalSubtasks > 0) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: todo.subtaskProgress, minHeight: 4,
                              backgroundColor: AppColors.greyLight(context),
                              valueColor: AlwaysStoppedAnimation<Color>(todo.subtaskProgress == 1.0 ? AppColors.success : AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${todo.completedSubtasks}/${todo.totalSubtasks}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.greyText(context))),
                      ]),
                    ],
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right_rounded, color: AppColors.greyBorder(context), size: 20),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.task_alt_rounded, size: 48, color: Color(0xFF6366F1)),
        ),
        const SizedBox(height: 16),
        Text('No tasks here!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.title(context))),
        const SizedBox(height: 6),
        Text('Tap the button below to add a task', style: TextStyle(fontSize: 13, color: AppColors.greyText(context))),
      ]),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }
}

class _AddTaskSheet extends StatefulWidget {
  final List<TaskType> allTaskTypes;
  final VoidCallback onTypeAdded;
  const _AddTaskSheet({required this.allTaskTypes, required this.onTypeAdded});
  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final TextEditingController _controller = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  DateTime? _startDate;
  String? _selectedTypeId;
  List<TaskType> _types = [];
  @override
  void initState() { super.initState(); _types = widget.allTaskTypes; }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:   return const Color(0xFFEF4444);
      case TaskPriority.medium: return const Color(0xFFF59E0B);
      case TaskPriority.low:    return const Color(0xFF10B981);
    }
  }
  IconData _priorityIcon(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:   return Icons.keyboard_double_arrow_up_rounded;
      case TaskPriority.medium: return Icons.drag_handle_rounded;
      case TaskPriority.low:    return Icons.keyboard_double_arrow_down_rounded;
    }
  }
  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<DateTime?> _pickDateTime({DateTime? initial}) async {
    final picked = await showDatePicker(context: context, initialDate: initial ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
    if (picked == null) return null;
    final pickedTime = await showTimePicker(context: context, initialTime: initial != null ? TimeOfDay.fromDateTime(initial) : TimeOfDay.now());
    if (pickedTime == null) return null;
    return DateTime(picked.year, picked.month, picked.day, pickedTime.hour, pickedTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Container(
        decoration: BoxDecoration(color: AppColors.card(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomInset + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.greyBorder(context), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.title(context))),
            const SizedBox(height: 16),
            TextField(
              controller: _controller, autofocus: true,
              decoration: InputDecoration(
                hintText: 'What needs to be done?', filled: true, fillColor: AppColors.inputFill(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            Text('Task Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.greyText(context))),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _types.length + 1,
                itemBuilder: (_, index) {
                  if (index == _types.length) return _buildAddCustomButton();
                  final type = _types[index];
                  final selected = _selectedTypeId == type.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTypeId = selected ? null : type.id),
                    onLongPress: type.isCustom ? () => _confirmDeleteType(type) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? type.color : type.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? type.color : type.color.withOpacity(0.2), width: 1.5),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(type.icon, color: selected ? Colors.white : type.color, size: 22),
                        const SizedBox(height: 4),
                        Text(type.name, style: TextStyle(fontSize: 11, color: selected ? Colors.white : type.color, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.greyText(context))),
            const SizedBox(height: 8),
            Row(
              children: TaskPriority.values.map((priority) {
                final isSelected = _priority == priority;
                final color = _priorityColor(priority);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = priority),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                      ),
                      child: Column(children: [
                        Icon(_priorityIcon(priority), color: isSelected ? Colors.white : color, size: 20),
                        const SizedBox(height: 4),
                        Text(priority.name.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color)),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildDateTile(label: 'Start Date', date: _startDate, icon: Icons.play_circle_outline_rounded, color: Colors.green, onTap: () async { final d = await _pickDateTime(initial: _startDate); if (d != null) setState(() => _startDate = d); }, onClear: () => setState(() => _startDate = null))),
              const SizedBox(width: 10),
              Expanded(child: _buildDateTile(label: 'Due Date', date: _dueDate, icon: Icons.flag_rounded, color: Colors.blue, onTap: () async { final d = await _pickDateTime(initial: _dueDate); if (d != null) setState(() => _dueDate = d); }, onClear: () => setState(() => _dueDate = null))),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    context.read<TodoBloc>().add(AddTodo(_controller.text.trim(), _priority, _dueDate, _startDate, taskTypeId: _selectedTypeId));
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                ),
                child: const Text('Add Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildAddCustomButton() {
    return GestureDetector(
      onTap: _showAddCustomTypeSheet,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: AppColors.inputFill(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.greyBorder(context), width: 1.5)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_rounded, color: AppColors.greyText(context), size: 22),
          const SizedBox(height: 4),
          Text('Custom', style: TextStyle(fontSize: 11, color: AppColors.greyText(context))),
        ]),
      ),
    );
  }

  Widget _buildDateTile({required String label, required DateTime? date, required IconData icon, required Color color, required VoidCallback onTap, required VoidCallback onClear}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: date != null ? color.withOpacity(0.08) : AppColors.inputFill(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: date != null ? color.withOpacity(0.3) : Colors.transparent),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: date != null ? color : AppColors.completedText(context)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: date != null ? color : AppColors.greyText(context))),
            const Spacer(),
            if (date != null) GestureDetector(onTap: onClear, child: Icon(Icons.close_rounded, size: 13, color: color.withOpacity(0.7))),
          ]),
          const SizedBox(height: 4),
          Text(date == null ? 'Not set' : _formatDate(date), style: TextStyle(fontSize: 11, color: date != null ? color : AppColors.completedText(context), fontWeight: date != null ? FontWeight.w500 : FontWeight.w400)),
        ]),
      ),
    );
  }

  void _showAddCustomTypeSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddCustomTypeSheet(
        onAdded: (type) async {
          widget.onTypeAdded();
          final types = await TaskTypeRepository.getAllTypes();
          setState(() { _types = types; _selectedTypeId = type.id; });
        },
      ),
    );
  }

  void _confirmDeleteType(TaskType type) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Type'),
        content: Text('Delete "${type.name}"? Tasks using this type will keep their data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await TaskTypeRepository.deleteCustomType(type.id);
              widget.onTypeAdded();
              final types = await TaskTypeRepository.getAllTypes();
              setState(() { _types = types; if (_selectedTypeId == type.id) _selectedTypeId = null; });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AddCustomTypeSheet extends StatefulWidget {
  final ValueChanged<TaskType> onAdded;
  const _AddCustomTypeSheet({required this.onAdded});
  @override
  State<_AddCustomTypeSheet> createState() => _AddCustomTypeSheetState();
}

class _AddCustomTypeSheetState extends State<_AddCustomTypeSheet> {
  final _nameController = TextEditingController();
  IconData _selectedIcon = availableIcons[0];
  Color _selectedColor = availableColors[0];
  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Container(
        decoration: BoxDecoration(color: AppColors.card(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomInset + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.greyBorder(context), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Create Custom Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: _selectedColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: _selectedColor.withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_selectedIcon, color: _selectedColor, size: 24),
                  const SizedBox(width: 10),
                  Text(_nameController.text.isEmpty ? 'Type name' : _nameController.text, style: TextStyle(color: _selectedColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController, onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: 'Type name (e.g. Gym, Hobby)', filled: true, fillColor: AppColors.inputFill(context), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 16),
            Text('Pick an Icon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.greyText(context))),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: availableIcons.map((icon) {
              final selected = _selectedIcon == icon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: selected ? _selectedColor : _selectedColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? _selectedColor : Colors.transparent)),
                  child: Icon(icon, color: selected ? Colors.white : _selectedColor, size: 22),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),
            Text('Pick a Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.greyText(context))),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: availableColors.map((color) {
              final selected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle,
                    border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 3),
                    boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)] : [],
                  ),
                  child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              );
            }).toList()),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: _selectedColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Create Type', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final newType = await TaskTypeRepository.addCustomType(name: name, iconCodePoint: _selectedIcon.codePoint, colorValue: _selectedColor.value);
    widget.onAdded(newType);
    Navigator.pop(context);
  }
}