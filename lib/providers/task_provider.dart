import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = true;
  int _currentTabIndex = 0;
  final NotificationService _notificationService = NotificationService();

  List<Task> get tasks => [..._tasks];
  bool get isLoading => _isLoading;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  Future<void> loadTasksForUser(String userId) async {
    final normalizedId = userId.toLowerCase();
    _isLoading = true;
    _tasks = []; // Clear current tasks to prevent stale data briefly appearing
    notifyListeners();
    
    try {
      // 1. Initial load
      var userTasks = await DatabaseService.instance.readTasksForUser(normalizedId);
      
      // 2. Migration: If this user has no tasks, check for 'guest' tasks from before login
      if (userTasks.isEmpty) {
        final migratedCount = await DatabaseService.instance.migrateGuestTasks(normalizedId);
        if (migratedCount > 0) {
          debugPrint('Migrated $migratedCount guest tasks to $normalizedId');
          userTasks = await DatabaseService.instance.readTasksForUser(normalizedId);
        }
      }
      
      _tasks = userTasks;
      _isLoading = false;
      notifyListeners();
      
      // Reschedule notifications in the background
      _notificationService.rescheduleAllTasks(_tasks).catchError((e) {
        debugPrint('Error rescheduling tasks: $e');
      });
    } catch (e) {
      debugPrint('Error loading tasks for user $normalizedId: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Task?> addTask({
    required String userId,
    required String title,
    required String description,
    required DateTime date,
  }) async {
    final normalizedId = userId.toLowerCase();
    try {
      final newTask = Task(
        id: Uuid().v4(),
        userId: normalizedId,
        title: title,
        description: description,
        date: date,
        avatars: [],
      );
      _tasks.add(newTask);
      await DatabaseService.instance.insertTask(newTask);
      
      // Schedule notification
      await _notificationService.scheduleTaskNotification(newTask);
      
      notifyListeners();
      return newTask;
    } catch (e) {
      debugPrint('Error adding task: $e');
      notifyListeners();
      return null;
    }
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      await DatabaseService.instance.updateTask(task);
      
      // Reschedule notification
      await _notificationService.scheduleTaskNotification(task);
      
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((task) => task.id == id);
    await DatabaseService.instance.deleteTask(id);
    
    // Cancel notification
    await _notificationService.cancelTaskNotification(id);
    
    notifyListeners();
  }

  Future<void> deleteAllTasks(String userId) async {
    _tasks.clear();
    await DatabaseService.instance.deleteAllTasksForUser(userId);
    
    // Cancel all notifications
    await _notificationService.cancelAllNotifications();
    
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = Task(
        id: task.id,
        userId: task.userId,
        title: task.title,
        description: task.description,
        progress: task.isCompleted ? 0.0 : 1.0,
        date: task.date,
        isCompleted: !task.isCompleted,
        avatars: task.avatars,
      );
      _tasks[index] = updatedTask;
      await DatabaseService.instance.updateTask(updatedTask);
      
      if (updatedTask.isCompleted) {
        await _notificationService.cancelTaskNotification(id);
      } else {
        await _notificationService.scheduleTaskNotification(updatedTask);
      }
      
      notifyListeners();
    }
  }
}
