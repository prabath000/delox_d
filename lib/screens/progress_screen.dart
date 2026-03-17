import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../app_theme.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import 'profile_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
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
    final now = DateTime.now();

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.tasks;
        
        // Filter tasks for the selected day in analytics
        final selectedDayTasks = tasks.where((t) => isSameDay(t.date, _selectedDay)).toList();
        final totalTasks = selectedDayTasks.length;
        final doneTasks = selectedDayTasks.where((t) => t.isCompleted).length;
        
        // Calculate weekly progress for the bar chart (always relative to the selected week)
        final List<double> weeklyProgress = _calculateWeeklyProgress(tasks, _selectedDay ?? now);
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final currentDayIndex = (_selectedDay ?? now).weekday - 1;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
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
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      }),
                      Row(
                        children: [
                          _buildIconButton(Icons.settings_outlined, theme, onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('Your Progress', style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    _selectedDay == null 
                        ? 'Select a date' 
                        : DateFormat('EEEE, dd MMMM yyyy').format(_selectedDay!),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  // Full Calendar View (Compact Format)
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
                      calendarFormat: CalendarFormat.week, // Use week format for Progress screen to save space
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      eventLoader: (day) {
                        return tasks.where((task) => isSameDay(task.date, day)).toList();
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
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Focus Mode Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.lavender.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Focus mode toggled! (Functionality coming soon)')),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    totalTasks > 0 && doneTasks == totalTasks 
                                        ? 'Perfect completion!' 
                                        : 'Focus mode is active', 
                                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 16)
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(totalTasks > 0 ? (doneTasks / totalTasks * 100).toStringAsFixed(0) : "0")}% of goals reached', 
                                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: Color(0xFF1A1A1A), shape: BoxShape.circle),
                              child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Bar Chart
                  SizedBox(
                    height: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        return _buildBar(
                          weekdays[index], 
                          weeklyProgress[index], 
                          index == currentDayIndex
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(doneTasks.toString(), 'Done', AppColors.peach.withValues(alpha: 0.5), theme),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(totalTasks.toString(), 'Total', AppColors.mint, theme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<double> _calculateWeeklyProgress(List<Task> tasks, DateTime baseDate) {
    final startOfWeek = baseDate.subtract(Duration(days: baseDate.weekday - 1)); // Monday
    final List<double> dailyPercentages = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
        final date = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i);
        final dayTasks = tasks.where((t) => isSameDay(t.date, date)).toList();

        if (dayTasks.isNotEmpty) {
            final doneOnDay = dayTasks.where((t) => t.isCompleted).length;
            dailyPercentages[i] = doneOnDay / dayTasks.length;
        }
    }
    return dailyPercentages;
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

  Widget _buildBar(String label, double progress, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 35,
          height: 150 * (progress.clamp(0.05, 1.0)), 
          decoration: BoxDecoration(
            color: isSelected ? AppColors.indigo : AppColors.lavender.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color bg, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 32),
          ),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
