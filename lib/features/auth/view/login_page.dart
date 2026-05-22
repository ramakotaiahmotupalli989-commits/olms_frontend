/// EduCinema LMS — Login Page
/// High-fidelity login with animated gradient background, floating glass card, and smooth transitions.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../repository/auth_repository.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late AnimationController _bgController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bgController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = AuthRepository();
      final data = await repo.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final role = data['role'];
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
        default:
          targetPath = '/login';
      }

      if (mounted) context.go(targetPath);
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        final msg = errStr.contains('401') 
            ? 'Incorrect email or password. Please try again.' 
            : 'Login failed: $errStr';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(msg, style: GoogleFonts.inter(fontSize: 13))),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated Gradient Background ──
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment(
                    0.5 + 0.5 * math.sin(_bgController.value * math.pi),
                    1.0 + 0.3 * math.cos(_bgController.value * math.pi),
                  ),
                  colors: const [
                    Color(0xFF0F0C29),
                    Color(0xFF302B63),
                    Color(0xFF24243E),
                  ],
                ),
              ),
            ),
          ),

          // ── Floating Orbs (decorative) ──
          Positioned(
            top: -80,
            right: -60,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, 20 * math.sin(_bgController.value * math.pi * 2)),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF667EEA).withValues(alpha: 0.3),
                        const Color(0xFF667EEA).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Transform.translate(
                offset: Offset(15 * math.cos(_bgController.value * math.pi * 2), 0),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF764BA2).withValues(alpha: 0.25),
                        const Color(0xFF764BA2).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Login Card ──
          Center(
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (_, child) => Opacity(
                opacity: _fadeAnim.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: child,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: isWide ? 420 : double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 60, offset: const Offset(0, 20)),
                      BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.1), blurRadius: 80, offset: const Offset(0, 40)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Logo ──
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: const Icon(Icons.play_circle_fill_rounded, size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text('Welcome Back', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                        const SizedBox(height: 6),
                        Text('Sign in to your EduCinema account', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 32),

                        // ── Fields ──
                        _buildEmailFields(),
                        const SizedBox(height: 28),

                        // ── Login Button ──
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: EdgeInsets.zero,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : Text(
                                        'Sign In',
                                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () {},
                          child: Text('Forgot Password?', style: GoogleFonts.inter(color: const Color(0xFF667EEA), fontWeight: FontWeight.w500, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildEmailFields() {
    return Column(
      key: const ValueKey('email'),
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Email Address',
            labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Enter your email' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (v) => v == null || v.length < 8 ? 'Minimum 8 characters' : null,
        ),
      ],
    );
  }


}
