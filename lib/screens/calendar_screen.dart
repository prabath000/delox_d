import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../app_theme.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/add_task_bottom_sheet.dart';
import 'profile_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _activeTab = 'All Tasks';
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = context.watch<TaskProvider>();
    
    // Filter tasks by selected date
    final dateFilteredTasks = taskProvider.tasks.where((task) {
      if (_selectedDay == null) return false;
      return isSameDay(task.date, _selectedDay);
    }).toList();

    // Filter tasks by status tab
    final filteredTasks = dateFilteredTasks.where((task) {
      if (_activeTab == 'Completed') return task.isCompleted;
      if (_activeTab == 'In Progress') return !task.isCompleted;
      return true; // "All Tasks"
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconButton(Icons.arrow_back_ios_new_rounded, theme, onTap: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  }),
                  Row(
                    children: [
                      _buildIconButton(Icons.link_rounded, theme, onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const AddTaskBottomSheet(isUrlTask: true),
                        );
                      }),
                      const SizedBox(width: 8),
                      _buildIconButton(Icons.settings_outlined, theme, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text('Your tasks', style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
              const SizedBox(height: 24),
              // Full Calendar View
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) {
                    return taskProvider.tasks.where((task) => isSameDay(task.date, day)).toList();
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.lavender.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: AppColors.indigo,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: AppColors.peach,
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Pill Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTabPill('All Tasks'),
                  _buildTabPill('In Progress'),
                  _buildTabPill('Completed'),
                ],
              ),
              const SizedBox(height: 24),
              // Task List
              Expanded(
                child: filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_turned_in_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text('No tasks found', style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredTasks.length,
                        padding: const EdgeInsets.only(bottom: 100), // Space for FAB
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return _buildTaskCard(task, theme);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, ThemeData theme, {bool hasBadge = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 22, color: theme.textTheme.bodyLarge?.color),
            if (hasBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(String label) {
    final isSelected = _activeTab == label;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _activeTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected ? null : Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('h:mm a').format(task.date),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  if (task.url != null && task.url!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.link, color: AppColors.indigo, size: 20),
                      onPressed: () async {
                        final uri = Uri.parse(task.url!);
                        try {
                          // ignore: deprecated_member_use
                          if (await canLaunchUrl(uri)) {
                            // ignore: deprecated_member_use
                            await launchUrl(uri);
                          }
                        } catch (e) {
                          debugPrint('Could not launch ${task.url}: $e');
                        }
                      },
                    ),
                  Checkbox(
                    value: task.isCompleted,
                    activeColor: AppColors.indigo,
                    shape: const CircleBorder(),
                    onChanged: (val) {
                      context.read<TaskProvider>().toggleTaskCompletion(task.id);
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AddTaskBottomSheet(taskToEdit: task),
                        );
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: const Text('Are you sure you want to delete this task?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          context.read<TaskProvider>().deleteTask(task.id);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            task.title, 
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? AppColors.textSecondary : null,
            )
          ),
          const SizedBox(height: 4),
          Text(
            task.description, 
            style: theme.textTheme.bodyMedium?.copyWith(
              color: task.isCompleted ? AppColors.textSecondary.withValues(alpha: 0.5) : null,
            )
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSmallPill(
                task.isCompleted ? 'Completed' : 'Upcoming', 
                task.isCompleted ? AppColors.mint.withValues(alpha: 0.2) : AppColors.lavender.withValues(alpha: 0.2),
                theme
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallPill(String label, Color bg, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMain),
      ),
    );
  }
}
