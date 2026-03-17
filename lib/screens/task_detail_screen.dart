import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../app_theme.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconButton(Icons.arrow_back_ios_new_rounded, theme),
                  const Text(
                    'Task Detail',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 30),
              // Date horizontal list
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
                    final date = 12 + index;
                    final isSelected = index == 3;
                    return Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            date.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            days[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : theme.textTheme.bodyMedium?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.list_alt_rounded, color: theme.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Research',
                            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                          ),
                          Text(
                            'Analyzing market trends',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'High !',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Percentage',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                  Text(
                    'See details >',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: CircularPercentIndicator(
                  radius: 100.0,
                  lineWidth: 15.0,
                  percent: 0.75,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "75%",
                        style: theme.textTheme.displayLarge?.copyWith(fontSize: 32),
                      ),
                      Text("Done", style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: theme.primaryColor,
                  backgroundColor: AppColors.border.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Task Overview',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   _buildDetailItem(context, 'Tasks', '12', AppColors.lavender),
                   _buildDetailItem(context, 'Weekly', '85%', theme.primaryColor),
                   _buildDetailItem(context, 'Total', '45', AppColors.peach),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Icon(icon, size: 22, color: theme.primaryColor),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 30.0,
          lineWidth: 6.0,
          percent: 0.65,
          progressColor: color,
          backgroundColor: AppColors.border.withValues(alpha: 0.2),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 12),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
      ],
    );
  }
}
