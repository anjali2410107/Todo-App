import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todoappp/model/todo_model.dart';

class FirestoreTodoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _todoCollection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('todos');
  }

  Future<List<TodoModel>> getTodos() async {
    try {
      final collection = _todoCollection;
      if (collection == null) return [];
      final snapshot = await collection.get();
      return snapshot.docs.map((doc) => TodoModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting todos: $e');
      return [];
    }
  }

  Stream<List<TodoModel>> getTodosStream() {
    final collection = _todoCollection;
    if (collection == null) return Stream.value([]);
    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TodoModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> addTodo(TodoModel todo) async {
    final collection = _todoCollection;
    if (collection == null) return;
    await collection.doc(todo.id).set(todo.toMap());
  }

  Future<void> deleteTodo(String id) async {
    final collection = _todoCollection;
    if (collection == null) return;
    await collection.doc(id).delete();
  }

  Future<void> toggleTodo(TodoModel todo) async {
    final collection = _todoCollection;
    if (collection == null) return;
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    await collection.doc(todo.id).set(updated.toMap());
  }

  Future<void> updateTodo(TodoModel updatedTodo) async {
    final collection = _todoCollection;
    if (collection == null) return;
    await collection.doc(updatedTodo.id).set(updatedTodo.toMap());
  }

  Future<void> migrateTodos(List<TodoModel> todos) async {
    final collection = _todoCollection;
    if (collection == null) return;
    final batch = _firestore.batch();
    for (final todo in todos) {
      batch.set(collection.doc(todo.id), todo.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
