import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api_service.dart';
import '../../../core/storage/token_storage.dart';
import 'client_shell.dart';
import 'admin_dashboard_screen.dart';
import 'register_screen.dart';
import 'worker_dashboard_screen.dart';
import '../../chat/services/socket_service.dart'; // ← chat

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;
  String? emailError;
  String? passwordError;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    final isLoggedIn = await TokenStorage.isLoggedIn();
    if (isLoggedIn && mounted) {
      final role = await TokenStorage.getUserRole();
      _navigateByRole(role);
    }
  }

  void _navigateByRole(String? role) {
    Widget screen;
    switch (role?.toLowerCase()) {
      case 'admin':
        screen = const AdminDashboardScreen();
        break;
      case 'worker':
        screen = const WorkerDashboardScreen();
        break;
      default:
        screen = const ClientShell();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 72),

              // Logo
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Hon',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: 'ar',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Skilled trades. Trusted Workers.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 52),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildField(
                controller: emailController,
                hint: 'email@example.com',
                keyboardType: TextInputType.emailAddress,
                error: emailError,
                onChanged: (_) => setState(() => emailError = null),
              ),

              const SizedBox(height: 18),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildField(
                controller: passwordController,
                hint: '••••••••••••••',
                isPassword: true,
                error: passwordError,
                onChanged: (_) => setState(() => passwordError = null),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? error,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: error != null ? Colors.red.shade400 : Colors.transparent,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && obscurePassword,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: InputBorder.none,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    )
                  : null,
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(
            error,
            style: TextStyle(color: Colors.red.shade600, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Future<void> _login() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    bool hasError = false;
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      setState(() => emailError = 'Please enter your email');
      hasError = true;
    } else if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email)) {
      setState(() => emailError = 'Please enter a valid email address');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => passwordError = 'Please enter your password');
      hasError = true;
    } else if (password.length < 8) {
      setState(() => passwordError = 'Password must be at least 8 characters');
      hasError = true;
    } else if (!password.contains(RegExp(r'[A-Z]'))) {
      setState(
        () =>
            passwordError = 'Password must contain at least 1 uppercase letter',
      );
      hasError = true;
    } else if (!password.contains(RegExp(r'[0-9]'))) {
      setState(() => passwordError = 'Password must contain at least 1 number');
      hasError = true;
    }

    if (hasError) return;

    setState(() => isLoading = true);

    try {
      await ApiService().login(email, password);
      if (mounted) {
        final role = await TokenStorage.getUserRole();
        Widget dest;
        switch (role?.toLowerCase()) {
          case 'admin':
            dest = const AdminDashboardScreen();
            break;
          case 'worker':
            dest = const WorkerDashboardScreen();
            break;
          default:
            dest = const ClientShell();
        }

        // Connect the socket so it's ready when the user opens a chat
        SocketService.instance.connect();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => dest),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF333333),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
