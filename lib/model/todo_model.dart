class TodoModel {
  final String id;
  final String title;
  final bool isCompleted;
   TodoModel(
  {
    required this.id,
    required this.title,
    this.isCompleted=false,
}
       );
}