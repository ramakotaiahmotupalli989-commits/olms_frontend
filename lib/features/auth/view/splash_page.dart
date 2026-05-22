/// EduCinema LMS — Splash Page
/// Handles initial authentication check and role-based routing.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../repository/auth_repository.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final repo = AuthRepository();
    final isLoggedIn = await repo.isLoggedIn();

    if (!mounted) return;

    if (!isLoggedIn) {
      context.go('/login');
      return;
    }

    final role = await repo.getRole();
    String targetPath = '/login';

    switch (role) {
      case AppConstants.superAdmin:
        targetPath = '/admin/dashboard';
        break;
      case AppConstants.schoolAdmin:
        targetPath = '/principal/dashboard';
        break;
      case AppConstants.teacher:
        targetPath = '/teacher/dashboard';
        break;
      case AppConstants.student:
        targetPath = '/student/dashboard';
        break;
      case AppConstants.parent:
        targetPath = '/parent/dashboard';
        break;
    }

    if (mounted) context.go(targetPath);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
