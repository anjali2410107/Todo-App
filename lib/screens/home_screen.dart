import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todoappp/enum.dart';
import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/todo/todo_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController controller = TextEditingController();
TaskPriority selectedPriority=TaskPriority.medium;
DateTime? selectedDueDate=null;
TaskFilter selectedFilter=TaskFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<TodoBloc>().add(LoadTodos());
  }
  void _showEditDialog(TodoModel todo)
  {
    final TextEditingController editingController=
    TextEditingController(text: todo.title);

    TaskPriority editPriority=todo.priority;

    DateTime?editDueDate=todo.dueDate;

    showDialog(context: context,
        builder: (dialogContext)
    {
      return AlertDialog(
        title: const Text('Edit Todo'),
        content: StatefulBuilder
          (builder:
        (innerContext,setStateDialog)
        {
          return Column(
            mainAxisSize: MainAxisSize.min,
children: [
  TextField(
    controller: editingController,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
    ),
  ),
  const SizedBox(height: 10,),
  DropdownButton<TaskPriority>
    (
    value: editPriority,
    isExpanded: true,
    items:TaskPriority.values.map((priority){
      return DropdownMenuItem(
        value: priority,
        child: Text(priority.name.toUpperCase()),
      );
    }).toList(),
    onChanged: (value)
    {
      setStateDialog(()
      {
        editPriority=value!;
      });
    },
  ),
  const SizedBox(height: 10,
  ),
  Text(editDueDate==null?"No Due Date":
  "Due:${editDueDate!.day}/${editDueDate!.month}/${editDueDate!.year}",
  ),
  TextButton(onPressed: () async
      {
        final picked=await showDatePicker
          (
          context: context,
          useRootNavigator: true,
          initialDate: editDueDate??DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
        );
        if(picked!=null)
          {
           final pickedTime=await showTimePicker
             (
           context: context,
             useRootNavigator: true,
             initialTime: editDueDate!=null
          ? TimeOfDay.fromDateTime(editDueDate!)
          :TimeOfDay.now(),
            );
           if(pickedTime!=null)
             {
               setStateDialog(()
               {
                 editDueDate=DateTime(
                   picked.year,
                   picked.month,
                   picked.day,
                   pickedTime.hour,
                   pickedTime.minute,
                 );
               }
               );
             }
          }
      },
      child: const Text("Changed Due Date"),
  ),
],
          );
        },
        ),
        actions: [
          TextButton(onPressed: ()
              {
               Navigator.pop(context);
              },
              child: const Text("Cancel"),
          ),
          ElevatedButton(onPressed: () {
            final updateTodo = TodoModel(id: todo.id,
              title: editingController.text,
              isCompleted: todo.isCompleted,
              priority: editPriority,
              dueDate: editDueDate,
            );
            context.read<TodoBloc>().add(
                UpdateTodoEvent(updatedTodo:updateTodo),);
            Navigator.pop(context);
          },
                child: const Text("Save"),
          ),
              ],
              );

    },);
  }

  Color getPriorityColor(TaskPriority priority)
  {
    switch(priority)
        {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orangeAccent;
        case TaskPriority.low:
      return Colors.green;
        }
  }
  List<TodoModel> applyFilterAndSort(List<TodoModel> todos)
  {
    final now =DateTime.now();
     List<TodoModel> filtered=todos.where((todo)
     {
       switch(selectedFilter)
           {
         case TaskFilter.overdue:
           return todo.dueDate!=null&&
       !todo.isCompleted&&todo.dueDate!.isBefore(now);
         case TaskFilter.completed:
           return todo.isCompleted;
         case TaskFilter.highPriority:
           return todo.priority==TaskPriority.high;
         case TaskFilter.all:
           default:
             return true;
       }
     }).toList();
     filtered.sort((a,b)
     {
       if(a.isCompleted&&!b.isCompleted)
         return 1;
       if(!a.isCompleted&&b.isCompleted)
         return -1;
       bool aOverdue=a.dueDate!=null
           && !a.isCompleted &&
           a.dueDate!.isBefore(now);
       bool bOverdue=b.dueDate!=null
           && !b.isCompleted &&
           b.dueDate!.isBefore(now);
       if(aOverdue&&!bOverdue) return -1;
       if(!aOverdue&& bOverdue) return 1;
       if(a.dueDate!=null&& bOverdue!=null) {
         int dateCompare = a.dueDate!.compareTo(b.dueDate!);
         if (dateCompare != 0) return dateCompare;}
       if(a.dueDate!=null)
         {
           return -1;
         }
       if(b.dueDate!=null) return 1;
       return a.priority.index.compareTo(b.priority.index);
     });
 return filtered;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todo App"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                          hintText: "Enter Todo Task",
                          border: OutlineInputBorder()
                      ),
                    ),
                    const SizedBox(height: 8,),
                    DropdownButton<TaskPriority>
                      (
                        value: selectedPriority,
                        isExpanded: true,
                        items: TaskPriority.values.map((priority)
                        {
                          return DropdownMenuItem(
                              value: priority,
                              child:Text(priority.name.toUpperCase()),
                          );
                        }
                        ).toList(),
                        onChanged: (value)
                    {
                      setState(() {
                        selectedPriority=value!;
                      });
                    }),
                    const SizedBox(height: 5,),
                    Row(
                      children: [
                        Expanded(child: Text(
                          selectedDueDate==null?
                          "No Due Date":
                          "Due: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}"
                              "${selectedDueDate!.hour.toString().padLeft(2,'0')}:"
                              "${selectedDueDate!.minute.toString().padLeft(2,'0')}"
                        ),),
                        IconButton(
                            onPressed: () async
    {
    final picked=await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
    );
    if(picked!=null)
    {
    final pickedTime=await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    );
    if(pickedTime!=null)
    {
    final combinedDataTime=DateTime(
    picked.year,
    picked.month,
    picked.day,
    pickedTime.hour,
    pickedTime.minute,
    );
    setState(() {
    selectedDueDate=combinedDataTime;
    });
    }
    }
    },
                            icon: const Icon(Icons.calendar_today),
                        )
                      ],
                    )
                  ],
                ),
                ),
                const SizedBox(width: 10,),
                ElevatedButton(onPressed: () {
                  if (controller.text.isNotEmpty) {
                    context.read<TodoBloc>().add(
                      AddTodo(controller.text,selectedPriority,selectedDueDate),
                    );
                    controller.clear();
                  }
                },
                  child: const Text("Add"),
                )
              ],
            ),
          ),
          SizedBox(height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: TaskFilter.values.map((filter)
            {
              final isSelected =selectedFilter==filter;
              return Padding(padding:
              const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                  label: Text(filter.name.toUpperCase()),
                  selected: isSelected,
              onSelected:(_)
                  {
                    setState(() {
                      selectedFilter=filter;
                    });
                  },
              ),
              );
            }).toList(),
          ),),
          Expanded(child:
          BlocBuilder<TodoBloc, TodoState>(
            builder: (context, state) {
              if (state is TodoLoaded) {
                final filteredTodos=applyFilterAndSort(state.todos);
                return ListView.builder(
                  itemCount: filteredTodos.length,
                  itemBuilder: (context, index) {
                    final todo = filteredTodos[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4,horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: getPriorityColor(todo.priority),
                            width: 6,
                          )
                        )
                      ),
                      child: ListTile(
                        onTap: ()
                        {
                          _showEditDialog(todo);
                        },
                        leading: Checkbox
                          (value: todo.isCompleted,
                          onChanged: (_) {
                            context.read<TodoBloc>().add(ToggleTodo(todo),
                            );
                          },),
                        title:
                        Text(
                          todo.title,
                          style: TextStyle(
                            decoration: todo.isCompleted ? TextDecoration
                                .lineThrough :
                            TextDecoration.none,
                          ),),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todo.priority.name.toUpperCase(),
                            style: TextStyle(
                              color: getPriorityColor(todo.priority),
                              fontWeight: FontWeight.bold,
                            ),
                            ),
                            if(todo.dueDate!=null)
                              Text(
                                    "Due: "
                                        "${todo.dueDate!.day}/${todo.dueDate!.month}/${todo.dueDate!.year} "
                                        "${todo.dueDate!.hour.toString().padLeft(2, '0')}:"
                                        "${todo.dueDate!.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(color: Colors.blue),
                              )
                          ],
                        ),
                        trailing: IconButton(onPressed: () {
                          context.read<TodoBloc>().add(DeleteTodo(todo.id));
                        },
                          icon: const Icon(Icons.delete),
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
          )
        ],
      ),

    );
  }
}
