import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/repository/todo_repository.dart';
import 'package:todoappp/todo/todo_bloc.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TodoBloc>().add(LoadTodos());
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
                Expanded(child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                      hintText: "Enter Todo",
                      border: OutlineInputBorder()
                  ),
                ),
                ),
                const SizedBox(width: 10,),
                ElevatedButton(onPressed: () {
                  if (controller.text.isNotEmpty) {
                    context.read<TodoBloc>().add(
                      AddTodo(controller.text),
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
                    return ListTile(
                      leading: Checkbox
                        (value: todo.isCompleted,
                        onChanged: (_) {
                          context:
                          context.read<TodoBloc>().add(ToggleTodo(todo),
                          );
                        },),
                      title:
                      Text(todo.title,
                        style: TextStyle(
                          decoration: todo.isCompleted ? TextDecoration
                              .lineThrough :
                          TextDecoration.none,
                        ),),
                      trailing: IconButton(onPressed: () {
                        context.read<TodoBloc>().add(DeleteTodo(todo.id));
                      },
                        icon: const Icon(Icons.delete),
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
