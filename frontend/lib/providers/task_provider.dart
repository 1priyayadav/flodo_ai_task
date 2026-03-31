import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Task> _tasks = [];
  bool _isLoading = false;
  String _error = '';
  
  // Local Filtering Logic (Architecture requirement)
  String _searchQuery = '';
  String _statusFilter = 'All';

  // Computed filtered list
  List<Task> get tasks {
    List<Task> filtered = _tasks;
    if (_statusFilter != 'All') {
      filtered = filtered.where((t) => t.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return filtered;
  }
  
  List<Task> get allTasks => _tasks; // Used for dependency resolution
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  Future<void> fetchTasks() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      _tasks = await _apiService.fetchTasks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<void> createTask(Task task) async {
    try {
      // 2-second simulated delay is already in the backend API
      await _apiService.createTask(task);
      await fetchTasks(); // Refresh state after mutation
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> updateTask(int id, Task task) async {
    try {
      await _apiService.updateTask(id, task);
      await fetchTasks();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _apiService.deleteTask(id);
      await fetchTasks(); // Cascade unblocking updates correctly retrieved
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Blocking logic computed locally in Flutter state
  bool isTaskBlocked(Task task) {
    if (task.blockedBy == null) return false;
    try {
      final blocker = _tasks.firstWhere((t) => t.id == task.blockedBy);
      return blocker.status != 'Done';
    } catch (e) {
      return false; // Blocker ID not found in list, fallback to unblocked
    }
  }

  String? getBlockerTitle(int? blockedById) {
    if (blockedById == null) return null;
    try {
      return _tasks.firstWhere((t) => t.id == blockedById).title;
    } catch (e) {
      return null;
    }
  }
}
