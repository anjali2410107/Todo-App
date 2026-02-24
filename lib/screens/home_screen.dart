import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<TodoBloc>().add(LoadTodos());
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
                          hintText: "Enter Todo",
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
                          selectedDueDate==null?"No Due Date":
                              "Due: ${selectedDueDate!.toLocal().toString().split(' ')[0]}",
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
                                setState(() {
                                  selectedDueDate=picked;
                                });
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
          Expanded(child:
          BlocBuilder<TodoBloc, TodoState>(
            builder: (context, state) {
              if (state is TodoLoaded) {
                return ListView.builder(
                  itemCount: state.todos.length,
                  itemBuilder: (context, index) {
                    final todo = state.todos[index];
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
                                "Due: ${todo.dueDate!.toLocal().toString().split(' ')[0]}",
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
