// lib/main.dart
// UPDATED — Admin routing added

import 'package:flutter/material.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/screens/admin_dashboard_screen.dart'; // NEW
import 'features/auth/screens/client_shell.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/worker_dashboard_screen.dart';

void main() {
  runApp(const HonarApp());
}

class HonarApp extends StatelessWidget {
  const HonarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Honar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        useMaterial3: true,
      ),
      home: const _SplashRouter(),
    );
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final token = await TokenStorage.getAccessToken();
    final role  = await TokenStorage.getUserRole();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      _go(const LoginScreen());
    } else if (role?.toLowerCase() == 'admin') {
      // ← NEW: Admin user ko Admin Dashboard pe bhejo
      _go(const AdminDashboardScreen());
    } else if (role?.toLowerCase() == 'worker') {
      _go(const WorkerDashboardScreen());
    } else {
      _go(const ClientShell());
    }
  }

  void _go(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.handyman,
                  color: AppColors.primary, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('Honar',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            const Text('Your trusted trade platform',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}
