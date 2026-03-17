import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import '../widgets/add_task_bottom_sheet.dart';
import '../providers/user_provider.dart';
import '../providers/task_provider.dart';
import 'package:provider/provider.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with WidgetsBindingObserver {
  final List<Widget> _screens = [
    const HomeScreen(),
    const CalendarScreen(),
    const ProgressScreen(),
    const ProfileScreen(),
  ];

  int _currentIndex = 0;
  String? _lastLoadedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Use a listener to detect when user session is restored
    // and tasks need to be loaded for specific user
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        
        // If we have a user and haven't loaded their tasks yet in this session
        if (user != null) {
          final normalizedId = user.email.toLowerCase();
          if (_lastLoadedUserId != normalizedId) {
            _lastLoadedUserId = normalizedId;
            // Trigger task load after build frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<TaskProvider>().loadTasksForUser(normalizedId);
              }
            });
          }
        } else {
          // Reset tracker if user logs out
          _lastLoadedUserId = null;
        }

        return Scaffold(
          body: _screens[_currentIndex],
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddTaskBottomSheet(),
              );
            },
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.add_rounded, size: 32),
          ),
          bottomNavigationBar: BottomAppBar(
            color: theme.colorScheme.surface,
            elevation: 20,
            padding: EdgeInsets.zero,
            height: 70,
            notchMargin: 12,
            shape: const CircularNotchedRectangle(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, Icons.home_outlined),
                _buildNavItem(1, Icons.assignment_rounded, Icons.assignment_outlined),
                const SizedBox(width: 48), // FAB Space
                _buildNavItem(2, Icons.bar_chart_rounded, Icons.bar_chart_outlined),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? theme.primaryColor : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
              size: 28,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
