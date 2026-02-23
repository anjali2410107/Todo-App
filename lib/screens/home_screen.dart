import 'package:flutter/material.dart';
import 'package:todoappp/main.dart';
import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/repository/todo_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TodoRepository repository = TodoRepository();
  final TextEditingController controller = TextEditingController();
  final uuid = const Uuid();

  List<TodoModel> todos = [];

  void initState()
  {
    super.initState();
      loadTodos();
    }


  void loadTodos() {
    todos = repository.getTodos();
    setState(() {});
  }
    void addTodo() async
    {
      if(controller.text.isEmpty) return;
      final todo=TodoModel(id: uuuid.v4(),
          title: controller.text,);
      await repository.addTodo(todo);
      controller.clear();
      loadTodos();
    }

    void deleteTodo(String id) async
    {
      await repository.deleteTodo(id);
      loadTodos();
    }

    void toggleTodo(TodoModel todo)async
    {
      await repository.toString(todo);
      loadTodos();
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

              ))
            ],
          ),
          )
        ],
      ),

    );
  }
}
