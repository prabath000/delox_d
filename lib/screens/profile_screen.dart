import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/task_provider.dart';
import 'login_screen.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<UserProvider, TaskProvider>(
      builder: (context, userProvider, taskProvider, child) {
        final user = userProvider.currentUser;

        // Use the real photo or a generated placeholder
        final String avatarUrl = (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
            ? user.photoUrl!
            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user?.name ?? "U")}&background=E91E8C&color=fff&bold=true&size=200';

        final int totalTasks = taskProvider.tasks.length;
        final int doneTasks = taskProvider.tasks.where((t) => t.isCompleted).length;
        final int pendingTasks = totalTasks - doneTasks;
        final bool isGoogleUser = user?.password == 'GOOGLE_AUTH';

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textTheme.bodyLarge?.color, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Profile', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // ---- Avatar with ring ----
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.indigo, AppColors.lavender],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: theme.colorScheme.surface,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                ),
                const SizedBox(height: 16),

                // ---- Name & badge ----
                Text(
                  user?.name ?? 'Guest User',
                  style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGoogleUser 
                        ? Colors.blue.withValues(alpha: 0.15) 
                        : theme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isGoogleUser 
                          ? Colors.blue.withValues(alpha: 0.4) 
                          : theme.primaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGoogleUser ? Icons.g_mobiledata_rounded : Icons.email_outlined,
                        size: 16,
                        color: isGoogleUser ? Colors.blueAccent : theme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isGoogleUser ? 'Google Account' : 'Email Account',
                        style: TextStyle(
                          color: isGoogleUser ? Colors.blueAccent : theme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ---- Task Stats ----
                Row(
                  children: [
                    _buildStatCard(context, 'Total', totalTasks.toString(), Icons.task_alt_rounded),
                    const SizedBox(width: 12),
                    _buildStatCard(context, 'Done', doneTasks.toString(), Icons.check_circle_outline_rounded, color: Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard(context, 'Pending', pendingTasks.toString(), Icons.pending_outlined, color: theme.primaryColor),
                  ],
                ),

                const SizedBox(height: 32),

                // ---- Account Details Section ----
                _buildSectionHeader(context, 'Account Details'),
                const SizedBox(height: 12),
                _buildDetailTile(
                  context,
                  icon: Icons.person_outline_rounded,
                  label: 'Full Name',
                  value: user?.name ?? '—',
                  onCopy: user?.name,
                ),
                const SizedBox(height: 10),
                _buildDetailTile(
                  context,
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: user?.email ?? '—',
                  onCopy: user?.email,
                ),
                const SizedBox(height: 10),
                _buildDetailTile(
                  context,
                  icon: Icons.lock_outline_rounded,
                  label: 'Password',
                  value: isGoogleUser ? 'Managed by Google' : '••••••••',
                ),

                const SizedBox(height: 28),

                // ---- Settings Section ----
                _buildSectionHeader(context, 'Settings'),
                const SizedBox(height: 12),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return _buildSettingsTile(
                      context,
                      Icons.dark_mode_outlined, 
                      'Dark Mode', 
                      themeProvider.isDarkMode ? 'Currently On' : 'Currently Off',
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(),
                        activeColor: theme.primaryColor,
                      ),
                      onTap: () => themeProvider.toggleTheme(),
                    );
                  },
                ),
                const SizedBox(height: 10),
                FutureBuilder<bool>(
                  future: NotificationService().checkPermissionStatus(),
                  builder: (context, snapshot) {
                    final bool isEnabled = snapshot.data ?? true;
                    return _buildSettingsTile(
                      context,
                      Icons.notifications_none_rounded, 
                      'Notifications', 
                      isEnabled ? 'Manage alerts' : 'Alerts are disabled',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isEnabled ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isEnabled ? 'Active' : 'Missing',
                          style: TextStyle(
                            color: isEnabled ? Colors.green : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () async {
                        await NotificationService().requestPermissions();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Checking notification permissions...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    );
                  }
                ),
                const SizedBox(height: 10),
                _buildSettingsTile(context, Icons.palette_outlined, 'Appearance', 'Theme & display'),
                const SizedBox(height: 10),
                _buildSettingsTile(
                  context,
                  Icons.delete_forever_rounded, 
                  'Delete All Tasks', 
                  'Clear all tasks and reminders',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('Delete All Tasks?', style: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
                        content: Text(
                          'This will permanently delete all your tasks and cancel all scheduled reminders. This action cannot be undone.',
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              if (userProvider.currentUser != null) {
                                await context.read<TaskProvider>().deleteAllTasks(userProvider.currentUser!.email);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('All tasks deleted successfully')),
                                  );
                                }
                              }
                            },
                            child: const Text('Delete All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // ---- Logout ----
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text('Sign Out?', style: TextStyle(color: theme.textTheme.titleLarge!.color, fontWeight: FontWeight.bold)),
                          content: Text('You will need to log in again to access your tasks.', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                userProvider.logout();
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              },
                              child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                        SizedBox(width: 12),
                        Text('SIGN OUT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, {Color color = Colors.black}) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(title, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildDetailTile(BuildContext context, {required IconData icon, required String label, required String value, String? onCopy}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 11)),
                const SizedBox(height: 3),
                Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (onCopy != null)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: onCopy));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                );
              },
              child: Icon(Icons.copy_rounded, color: theme.textTheme.bodyMedium?.color, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, String subtitle, {Widget? trailing, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing,
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, color: theme.textTheme.bodyMedium?.color, size: 14),
          ],
        ),
      ),
    );
  }
}
