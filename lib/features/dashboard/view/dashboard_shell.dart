/// EduCinema LMS — Dashboard Shell
/// Premium role-aware navigation shell with glassmorphic sidebar and refined top bar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/repository/auth_repository.dart';

// ─────────────────────────────────────────────
// Sidebar menu item definition
// ─────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  const _MenuItem(this.icon, this.label, this.route);
}

class DashboardShell extends StatefulWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _role = '';
  String _userName = '';
  bool _sidebarCollapsed = false;
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final role = await _storage.read(key: AppConstants.userRoleKey) ?? '';
    final name = await _storage.read(key: 'user_name') ?? 'User';
    if (mounted) {
      setState(() {
        _role = role;
        _userName = name;
      });
    }
  }

  // ── Role-based menu items ──
  List<_MenuItem> get _menuItems {
    switch (_role) {
      case AppConstants.superAdmin:
        return const [
          _MenuItem(Icons.dashboard_rounded, 'Dashboard', '/admin/dashboard'),
          _MenuItem(Icons.school_rounded, 'Schools', '/admin/schools'),
          _MenuItem(Icons.video_library_rounded, 'Content (CMS)', '/admin/cms'),
          _MenuItem(Icons.card_membership_rounded, 'Subscriptions', '/admin/subscriptions'),
          _MenuItem(Icons.analytics_rounded, 'Performance', '/admin/performance'),
          _MenuItem(Icons.campaign_rounded, 'Broadcasts', '/admin/broadcasts'),
          _MenuItem(Icons.play_circle_rounded, 'Watch Hours', '/admin/watch-hours'),
          _MenuItem(Icons.notifications_rounded, 'Notifications', '/notifications'),
        ];
      case AppConstants.schoolAdmin:
        return const [
          _MenuItem(Icons.dashboard_rounded, 'Dashboard', '/principal/dashboard'),
          _MenuItem(Icons.class_rounded, 'Classes & Sections', '/principal/classes'),
          _MenuItem(Icons.people_alt_rounded, 'Teachers', '/principal/teachers'),
          _MenuItem(Icons.how_to_reg_rounded, 'Staff Attendance', '/principal/attendance'),
          _MenuItem(Icons.bar_chart_rounded, 'Student Perf.', '/principal/student-performance'),
          _MenuItem(Icons.pie_chart_rounded, 'Class Perf.', '/principal/class-performance'),
          _MenuItem(Icons.assignment_rounded, 'Exam Results', '/principal/exam-results'),
          _MenuItem(Icons.account_balance_wallet_rounded, 'Salary Mgmt', '/principal/salaries'),
          _MenuItem(Icons.receipt_long_rounded, 'Fee Mgmt', '/principal/fees'),
          _MenuItem(Icons.calendar_view_week_rounded, 'Timetable', '/principal/timetable'),
          _MenuItem(Icons.notifications_rounded, 'Notifications', '/notifications'),
        ];
      case AppConstants.teacher:
        return const [
          _MenuItem(Icons.dashboard_rounded, 'Dashboard', '/teacher/dashboard'),
          _MenuItem(Icons.play_lesson_rounded, 'Content Library', '/teacher/library'),
          _MenuItem(Icons.quiz_rounded, 'Quizzes & Tests', '/teacher/quizzes'),
          _MenuItem(Icons.home_work_rounded, 'Homework', '/teacher/homework'),
          _MenuItem(Icons.how_to_reg_rounded, 'Attendance', '/teacher/attendance'),
          _MenuItem(Icons.assignment_rounded, 'Exam Scores', '/teacher/exams'),
          _MenuItem(Icons.analytics_rounded, 'Analytics', '/teacher/analytics'),
          _MenuItem(Icons.account_balance_wallet_rounded, 'My Salary', '/teacher/salary'),
          _MenuItem(Icons.calendar_view_week_rounded, 'My Schedule', '/teacher/schedule'),
          _MenuItem(Icons.notifications_rounded, 'Notifications', '/notifications'),
        ];
      case AppConstants.student:
        return const [
          _MenuItem(Icons.dashboard_rounded, 'Dashboard', '/student/dashboard'),
          _MenuItem(Icons.how_to_reg_rounded, 'Attendance', '/student/attendance'),
          _MenuItem(Icons.home_work_rounded, 'Homework', '/student/homework'),
          _MenuItem(Icons.assignment_rounded, 'Exam Results', '/student/exam-results'),
          _MenuItem(Icons.receipt_long_rounded, 'Fee Status', '/student/fees'),
          _MenuItem(Icons.calendar_view_week_rounded, 'Timetable', '/student/timetable'),
          _MenuItem(Icons.notifications_rounded, 'Notifications', '/notifications'),
        ];
      case AppConstants.parent:
        return const [
          _MenuItem(Icons.dashboard_rounded, 'Dashboard', '/parent/dashboard'),
          _MenuItem(Icons.assignment_rounded, 'Exam Results', '/parent/exam-results'),
          _MenuItem(Icons.notifications_rounded, 'Notifications', '/notifications'),
        ];
      default:
        return const [
          _MenuItem(Icons.dashboard_rounded, 'Dashboard', '/login'),
          _MenuItem(Icons.login_rounded, 'Sign In', '/login'),
        ];
    }
  }

  bool _isActiveRoute(BuildContext context, String route) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    return currentLocation == route;
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 40),
        title: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out of your account?', style: GoogleFonts.inter(color: AppColors.textSecondary), textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Sign Out', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthRepository().logout();
      if (mounted) context.go('/login');
    }
  }

  void _showProfileMenu(BuildContext context, Offset position) {
    final roleLabel = _role.replaceAll('_', ' ').split(' ').map((w) =>
      w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
    ).join(' ');

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy + 10, position.dx + 1, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                    Text(roleLabel, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: 10),
              Text('Sign Out', style: GoogleFonts.inter(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'logout') _handleLogout();
    });
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;
    // Navigate to matching menu item if found
    final lowerQuery = query.toLowerCase();
    for (final item in _menuItems) {
      if (item.label.toLowerCase().contains(lowerQuery)) {
        context.go(item.route);
        _searchController.clear();
        setState(() => _isSearchExpanded = false);
        _searchFocusNode.unfocus();
        return;
      }
    }
    // Show snackbar if no match
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No matching section found for "$query"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isWide) _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide ? null : _buildBottomNav(context),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final items = _menuItems;
    final sidebarWidth = _sidebarCollapsed ? 72.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1F3A),
            Color(0xFF0F1225),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(4, 0)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          // ── Brand ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 12 : 20),
            child: Row(
              mainAxisAlignment: _sidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Text('EduCinema', style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Collapse toggle
          Align(
            alignment: _sidebarCollapsed ? Alignment.center : Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: _sidebarCollapsed ? 0 : 12),
              child: IconButton(
                icon: Icon(
                  _sidebarCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
                onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Divider
          Container(margin: const EdgeInsets.symmetric(horizontal: 16), height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // ── Nav Items ──
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 8 : 12),
              children: items.map((item) => _sidebarItem(
                context, item.icon, item.label, item.route, _isActiveRoute(context, item.route),
              )).toList(),
            ),
          ),

          // ── Bottom: User info + Logout ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 12),
          if (!_sidebarCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF667EEA).withValues(alpha: 0.3),
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _userName,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          _sidebarActionItem(Icons.logout_rounded, 'Sign Out', _handleLogout),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, IconData icon, String label, String route, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () { if (!isActive) context.go(route); },
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.05),
          splashColor: Colors.white.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarCollapsed ? 12 : 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF5A4FCF)])
                  : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: _sidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sidebarActionItem(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 8 : 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.error.withValues(alpha: 0.1),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarCollapsed ? 12 : 14,
              vertical: 11,
            ),
            child: Row(
              mainAxisAlignment: _sidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(label, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w400, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Responsive Top Bar ──
  Widget _buildTopBar(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;
    final isMobile = screenWidth <= 600;

    String pageTitle = 'Dashboard';
    for (final item in _menuItems) {
      if (currentLocation == item.route) {
        pageTitle = item.label;
        break;
      }
    }

    return Container(
      padding: EdgeInsets.only(
        left: isMobile ? 16 : 24,
        right: isMobile ? 12 : 24,
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: _isSearchExpanded && isMobile
          ? _buildExpandedSearchBar()
          : Row(
              children: [
                // Title + greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pageTitle,
                        style: GoogleFonts.outfit(
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getGreeting(),
                        style: GoogleFonts.inter(fontSize: isMobile ? 11 : 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Search
                if (isWide)
                  _buildDesktopSearchField()
                else
                  _buildIconButton(
                    Icons.search_rounded,
                    onPressed: () => setState(() {
                      _isSearchExpanded = true;
                      Future.microtask(() => _searchFocusNode.requestFocus());
                    }),
                    tooltip: 'Search',
                  ),
                SizedBox(width: isMobile ? 4 : 12),
                // Notification bell
                _buildIconButton(
                  Icons.notifications_outlined,
                  onPressed: () => context.go('/notifications'),
                  tooltip: 'Notifications',
                ),
                SizedBox(width: isMobile ? 4 : 8),
                // Profile avatar
                GestureDetector(
                  onTapDown: (details) => _showProfileMenu(context, details.globalPosition),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                    ),
                    child: CircleAvatar(
                      radius: isMobile ? 14 : 17,
                      backgroundColor: Colors.white,
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: GoogleFonts.outfit(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIconButton(IconData icon, {required VoidCallback onPressed, String? tooltip}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildDesktopSearchField() {
    return SizedBox(
      width: 200,
      height: 36,
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onSubmitted: _handleSearch,
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.featureBlue, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildExpandedSearchBar() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onSubmitted: _handleSearch,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search sections...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.featureBlue, width: 1.5)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            _searchController.clear();
            _searchFocusNode.unfocus();
            setState(() => _isSearchExpanded = false);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $_userName';
    if (hour < 17) return 'Good afternoon, $_userName';
    return 'Good evening, $_userName';
  }

  // ── Horizontal Scrollable Bottom Nav ──
  Widget _buildBottomNav(BuildContext context) {
    final items = _menuItems;
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: items.map((item) {
                final isActive = currentLocation == item.route;
                return _buildBottomNavItem(item, isActive);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(_MenuItem item, bool isActive) {
    final shortLabel = item.label.length > 12
        ? item.label.split(' ').first
        : item.label;

    return GestureDetector(
      onTap: () {
        if (!isActive) context.go(item.route);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              shortLabel,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
