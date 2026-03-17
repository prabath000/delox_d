import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';

class AddTaskBottomSheet extends StatefulWidget {
  final Task? taskToEdit;
  const AddTaskBottomSheet({super.key, this.taskToEdit});

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _descController.text = widget.taskToEdit!.description;
      _selectedDate = widget.taskToEdit!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.taskToEdit!.date);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: theme,
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final theme = Theme.of(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: theme,
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.taskToEdit != null ? 'Edit Task' : 'Add New Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: theme.textTheme.bodyMedium?.color),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Task Title', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: const InputDecoration(hintText: 'Enter task title'),
          ),
          const SizedBox(height: 20),
          Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: const InputDecoration(hintText: 'Enter task description'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPickerButton(
                  icon: Icons.calendar_today_rounded,
                  label: DateFormat('MMM dd, yyyy').format(_selectedDate),
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPickerButton(
                  icon: Icons.access_time_rounded,
                  label: _selectedTime.format(context),
                  onTap: () => _selectTime(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isNotEmpty) {
                final provider = context.read<TaskProvider>();
                final userProvider = context.read<UserProvider>();
                final userId = userProvider.currentUser?.email ?? 'guest';
                final notifService = NotificationService();
                
                if (widget.taskToEdit != null) {
                  final updatedTask = Task(
                    id: widget.taskToEdit!.id,
                    userId: widget.taskToEdit!.userId,
                    title: _titleController.text,
                    description: _descController.text,
                    date: combinedDateTime,
                    progress: widget.taskToEdit!.progress,
                    avatars: widget.taskToEdit!.avatars,
                    isCompleted: widget.taskToEdit!.isCompleted,
                  );
                  await provider.updateTask(updatedTask);

                  try {
                    await notifService.showImmediateNotification(
                      title: '✏️ Task Updated',
                      body: '"${updatedTask.title}" has been updated.',
                    );
                  } catch (e) {
                    debugPrint('Notification error on update: $e');
                  }
                } else {
                  final newTask = await provider.addTask(
                    userId: userId,
                    title: _titleController.text,
                    description: _descController.text,
                    date: combinedDateTime,
                  );
                  if (newTask != null) {
                    try {
                      await notifService.showImmediateNotification(
                        title: '✅ Task Created',
                        body: '"${newTask.title}" scheduled for ${DateFormat('MMM dd, h:mm a').format(newTask.date)}.',
                      );
                    } catch (e) {
                      debugPrint('Notification error on create: $e');
                    }
                  }
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(widget.taskToEdit != null ? 'UPDATE TASK' : 'SAVE TASK'),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerButton({required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
          ],
        ),
      ),
    );
  }
}
