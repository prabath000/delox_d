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
    final isDark = theme.brightness == Brightness.dark;
    final btnColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final btnTextColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Back button aligned left
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryColor, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Logo centered
              Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.rocket_launch_rounded, size: 64, color: theme.primaryColor);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'DELOX',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Create Account',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 30, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Start your productivity journey with us.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              // Full Name field
              _buildLabel('Full Name', theme),
              const SizedBox(height: 8),
              _buildTextField(
                'Your Name',
                controller: _nameController,
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 20),
              // Email field
              _buildLabel('Email Address', theme),
              const SizedBox(height: 8),
              _buildTextField(
                'youremail@gmail.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 20),
              // Password field
              _buildLabel('Password', theme),
              const SizedBox(height: 8),
              _buildTextField(
                '••••••••••••',
                obscureText: _obscurePassword,
                controller: _passwordController,
                prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 32),
              // Sign Up button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    foregroundColor: btnTextColor,
                    elevation: 4,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: _isLoading
                      ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: btnTextColor, strokeWidth: 2))
                      : Text('SIGN UP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: btnTextColor)),
                ),
              ),
              const SizedBox(height: 28),
              // OR divider
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
              const SizedBox(height: 28),
              // Google button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: theme.colorScheme.surface,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GoogleIcon(),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final result = await context.read<UserProvider>().register(name, email, password);
      if (!mounted) return;
      if (result == "success") {
        messenger.showSnackBar(const SnackBar(content: Text('Registration Successful! Please Sign In.')));
        navigator.pop();
      } else {
        messenger.showSnackBar(SnackBar(content: Text(result)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
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
        navigator.pushReplacement(MaterialPageRoute(builder: (context) => const MainScaffold()));
      } else if (result != "cancelled") {
        messenger.showSnackBar(SnackBar(content: Text(result)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLabel(String label, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.textTheme.bodyLarge?.color)),
    );
  }

  Widget _buildTextField(String hint, {
    bool obscureText = false,
    Widget? suffixIcon,
    Widget? prefixIcon,
    TextInputType? keyboardType,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Real Google G logo via CustomPaint (stroke arcs + horizontal bar)
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Offset center = Offset(s / 2, s / 2);
    const double pi = 3.14159265358979;

    final double outer = s / 2;
    final double inner = outer * 0.58;
    final double mid = (outer + inner) / 2;
    final double sw = outer - inner;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    final Rect rect = Rect.fromCircle(center: center, radius: mid);

    // Notch (G opening) on the right, ±30°. Visible arc = 300°.
    const double notchBottom = pi / 6;       // 30°
    const double greenSweep  = pi * 2 / 3;  // 120°
    const double yellowSweep = pi * 5 / 12; // 75°
    const double redSweep    = pi * 7 / 12; // 105°

    paint.color = const Color(0xFF34A853); // Green
    canvas.drawArc(rect, notchBottom, greenSweep, false, paint);

    paint.color = const Color(0xFFFBBC05); // Yellow
    canvas.drawArc(rect, notchBottom + greenSweep, yellowSweep, false, paint);

    paint.color = const Color(0xFFEA4335); // Red
    canvas.drawArc(rect, notchBottom + greenSweep + yellowSweep, redSweep, false, paint);

    // Blue horizontal bar clipped to circle
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: outer)));
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(center.dx, center.dy - sw / 2, outer, sw), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
