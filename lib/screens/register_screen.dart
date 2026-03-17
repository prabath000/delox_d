import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/user_provider.dart';
import '../providers/task_provider.dart';
import 'main_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryColor, size: 20),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'DELOX',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create Account',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'Start your productivity journey with us.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              _buildLabel('Full Name', theme),
              const SizedBox(height: 8),
              _buildTextField('Your Name', controller: _nameController),
              const SizedBox(height: 24),
              _buildLabel('Email Address', theme),
              const SizedBox(height: 8),
              _buildTextField('youremail@gmail.com', controller: _emailController),
              const SizedBox(height: 24),
              _buildLabel('Password', theme),
              const SizedBox(height: 8),
              _buildTextField(
                '••••••••••••', 
                obscureText: _obscurePassword, 
                controller: _passwordController,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  final name = _nameController.text.trim();
                  final email = _emailController.text.trim();
                  final password = _passwordController.text;

                  if (name.isEmpty || email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);
                  try {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final userProvider = context.read<UserProvider>();
                    final result = await userProvider.register(name, email, password);
                    
                    if (!mounted) return;
                    
                    if (result == "success") {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Registration Successful! Please Sign In.')),
                      );
                      navigator.pop(); // Go back to LoginScreen
                    } else {
                      messenger.showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('SIGN UP'),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.5))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.5))),
                ],
              ),
              const SizedBox(height: 30),
              OutlinedButton(
                onPressed: _isLoading ? null : () async {
                  setState(() => _isLoading = true);
                  try {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final userProvider = context.read<UserProvider>();
                    final taskProvider = context.read<TaskProvider>();
                    final result = await userProvider.signInWithGoogle();
                    
                    if (!mounted) return;
                    
                    if (result == "success") {
                      final userId = userProvider.currentUser!.email;
                      await taskProvider.loadTasksForUser(userId);
                      if (!mounted) return;
                      navigator.pushReplacement(
                        MaterialPageRoute(builder: (context) => const MainScaffold()),
                      );
                    } else if (result != "cancelled") {
                      messenger.showSnackBar(SnackBar(content: Text(result)));
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.login, color: AppColors.indigo, size: 20),
                    const SizedBox(width: 12),
                    Text('CONTINUE WITH GOOGLE', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Sign In', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, ThemeData theme) {
    return Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.bodyLarge?.color));
  }

  Widget _buildTextField(String hint, {bool obscureText = false, Widget? suffixIcon, TextInputType? keyboardType, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
