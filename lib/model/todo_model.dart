class TodoModel {
  final String id;
  final String title;
  final bool isCompleted;
   TodoModel
       (
  {
    required this.id,
    required this.title,
    this.isCompleted=false,
});
Map<String,dynamic> toMap()
{
  return{
    'id':id,
    'title':title,
    'isComplete':isCompleted,
  };
}
factory TodoModel.fromMap(Map map)
  {
    return TodoModel(
        id: map['id'],
        title: map['title'],
    isCompleted: map['isCompleted'],
    );
  }
}