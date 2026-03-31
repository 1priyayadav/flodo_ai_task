import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/tasks';

  Future<List<Task>> fetchTasks() async {
    try {
        final response = await http.get(Uri.parse(baseUrl));
        if (response.statusCode == 200) {
            List jsonResponse = json.decode(response.body);
            return jsonResponse.map((task) => Task.fromJson(task)).toList();
        } else {
            throw Exception('Failed to load tasks');
        }
    } catch (e) {
        throw Exception('Network error: $e');
    }
  }

  Future<Task> createTask(Task task) async {
      final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(task.toJson()),
      );
      if (response.statusCode == 200) {
          return Task.fromJson(json.decode(response.body));
      } else {
          final error = json.decode(response.body);
          throw Exception(error['detail'] ?? 'Failed to create task');
      }
  }

  Future<Task> updateTask(int id, Task task) async {
      final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(task.toJson()),
      );
      if (response.statusCode == 200) {
          return Task.fromJson(json.decode(response.body));
      } else {
          final error = json.decode(response.body);
          throw Exception(error['detail'] ?? 'Failed to update task');
      }
  }

  Future<void> deleteTask(int id) async {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      if (response.statusCode != 200) {
          throw Exception('Failed to delete task');
      }
  }
}
