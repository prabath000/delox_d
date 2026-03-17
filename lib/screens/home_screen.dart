import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';
import '../widgets/add_task_bottom_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final user = userProvider.currentUser;
    final allTasks = taskProvider.tasks;
    
    // Calculate dynamic stats
    final now = DateTime.now();
    final todayTasks = allTasks.where((t) => 
      t.date.year == now.year && t.date.month == now.month && t.date.day == now.day
    ).toList();
    
    final doneToday = todayTasks.where((t) => t.isCompleted).length;
    final onHold = allTasks.where((t) => !t.isCompleted && t.date.isAfter(now)).length; 
    final pastDue = allTasks.where((t) => !t.isCompleted && t.date.isBefore(DateTime(now.year, now.month, now.day))).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: taskProvider.isLoading && allTasks.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: theme.primaryColor),
                    const SizedBox(height: 16),
                    Text('Loading your tasks...', style: theme.textTheme.bodyMedium),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Custom Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(user?.photoUrl ?? 'https://ui-avatars.com/api/?name=${user?.name ?? "U"}&background=B5B8F9&color=fff'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Hey, ${user?.name.split(' ').first ?? 'Sara'}',
                              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                            ),
                          ],
                        ),
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
                    const SizedBox(height: 40),
                    // Big Title
                    Text(
                      'Start today\'s\ntasks.',
                      style: theme.textTheme.displayLarge?.copyWith(
                        height: 1.1,
                        color: theme.textTheme.displayLarge?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Grid Categories
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        _buildCategoryCard('Today', '${todayTasks.length.toString().padLeft(2, '0')} Task', Icons.calendar_today_rounded, AppColors.mint, theme),
                        _buildCategoryCard('Completed', '${doneToday.toString().padLeft(2, '0')} Task', Icons.done_all_rounded, AppColors.lavender.withValues(alpha: 0.3), theme),
                        _buildCategoryCard('On Hold', '${onHold.toString().padLeft(2, '0')} Task', Icons.hourglass_bottom_rounded, AppColors.peach.withValues(alpha: 0.3), theme),
                        _buildCategoryCard('Past Due', '${pastDue.toString().padLeft(2, '0')} Task', Icons.event_busy_rounded, AppColors.lavender.withValues(alpha: 0.6), theme),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Today\'s tasks', style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
                        TextButton(
                          onPressed: () {},
                          child: Text('View All', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Horizontal Task List
                    if (todayTasks.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.task_alt_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text('No tasks for today', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...todayTasks.take(5).map((task) => _buildHorizontalTaskCard(task, theme, context)),
                    const SizedBox(height: 30),
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
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 22, color: theme.primaryColor),
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

  Widget _buildCategoryCard(String title, String count, IconData icon, Color bg, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 24, color: AppColors.indigo.withValues(alpha: 0.7)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count, style: theme.textTheme.displayLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTaskCard(Task task, ThemeData theme, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            activeColor: AppColors.indigo,
            shape: const CircleBorder(),
            onChanged: (val) {
              context.read<TaskProvider>().toggleTaskCompletion(task.id);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('h:mm-h:mm a').format(task.date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: task.isCompleted ? Colors.grey : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (task.url != null && task.url!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
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
            ),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lavender.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.more_vert_rounded, color: AppColors.indigo, size: 20),
            ),
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
    );
  }
}
