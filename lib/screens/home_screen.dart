import 'package:flutter/material.dart';
import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/repository/todo_repository.dart';
import 'package:uuid/uuid.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TodoRepository repository = TodoRepository();
  final TextEditingController controller = TextEditingController();
  final Uuid uuid =  Uuid();

  List<TodoModel> todos = [];
  @override
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
      final todo=TodoModel(id: uuid.v4(),
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
      await repository.toggleTodo(todo);
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
              ),
              ),
              const SizedBox(width: 10,),
              ElevatedButton(onPressed: addTodo, child: const Text("Add"),
              )
            ],
          ),
          ),
          Expanded(child:
          ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context,index)
    {
      final todo=todos[index];
      return ListTile(
    leading: Checkbox(value: todo.isCompleted,
    onChanged: (_) =>toggleTodo(todo),
    ),
    title: Text(todo.title,
    style: TextStyle(
    decoration: todo.isCompleted? TextDecoration.lineThrough:
    TextDecoration.none,
    ),),
    trailing: IconButton(onPressed: () =>deleteTodo(todo.id),
    icon: const Icon(Icons.delete),
    ),

    );

    },
    ),
          )
        ],
      ),

    );
  }
}
