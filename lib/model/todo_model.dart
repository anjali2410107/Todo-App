
enum TaskPriority
{
  high,
  medium,
  low
}
class TodoModel {
  final String id;
  final String title;
  final bool isCompleted;
  final TaskPriority priority;

   TodoModel
       (
  {
    required this.id,
    required this.title,
    this.isCompleted=false,
    this.priority=TaskPriority.medium,
});
Map<String,dynamic> toMap()
{
  return{
    'id':id,
    'title':title,
    'isCompleted':isCompleted,
    'priority':priority.name,
  };
}
factory TodoModel.fromMap(Map<String,dynamic> map)
  {
    return TodoModel(
        id: map['id'],
        title: map['title'],
    isCompleted: map['isCompleted']?? false,
      priority: TaskPriority.values.firstWhere((e)
        => e.name==map['priority'],orElse: ()=>TaskPriority.medium,
      ),
    );
  }
}