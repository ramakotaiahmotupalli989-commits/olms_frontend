/// EduCinema LMS — App Router
/// Role-aware GoRouter with shell navigation and all feature routes.
library;

import 'package:go_router/go_router.dart';

import '../../features/auth/view/login_page.dart';
import '../../features/dashboard/view/dashboard_shell.dart';
import '../../features/super_admin/view/super_admin_dashboard.dart';
import '../../features/principal/view/principal_dashboard.dart';
import '../../features/principal/view/teacher_management_page.dart';
import '../../features/principal/view/classroom_management_page.dart';
import '../../features/principal/view/student_performance_page.dart';
import '../../features/principal/view/class_performance_page.dart';
import '../../features/teacher/view/teacher_dashboard.dart';
import '../../features/teacher/view/class_roster_page.dart';
import '../../features/teacher/view/teacher_content_library_page.dart';
import '../../features/teacher/view/teacher_quiz_management_page.dart';
import '../../features/teacher/view/presentation_player_page.dart';
import '../../features/teacher_analytics/view/performance_overview.dart';
import '../../features/student/view/student_dashboard.dart';
import '../../features/student/view/subject_chapters_page.dart';
import '../../features/student/view/quiz_page.dart';
import '../../features/parent/view/parent_dashboard.dart';
import '../../features/ranking/view/ranking_page.dart';
import '../../features/notifications/view/notifications_page.dart';
import '../../features/attendance/view/attendance_management_page.dart';
import '../../features/teacher/view/teacher_attendance_page.dart';
import '../../features/teacher/view/exam_management_page.dart';
import '../../features/principal/view/exam_results_page.dart';
import '../../features/super_admin/view/school_management_page.dart';
import '../../features/super_admin/view/cms_management_page.dart';
import '../../features/super_admin/view/subscription_management_page.dart';
import '../../features/super_admin/view/platform_performance_page.dart';
import '../../features/super_admin/view/notification_broadcast_page.dart';
import '../../features/super_admin/view/watch_hours_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // ── Root Redirect ──
      GoRoute(
        path: '/',
        redirect: (context, state) => '/login',
      ),
      // ── Auth ──
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // ── Dashboard Shell (with sidebar/bottom nav) ──
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          // Super Admin
          GoRoute(path: '/admin/dashboard', builder: (context, state) => const SuperAdminDashboard()),
          GoRoute(path: '/admin/schools', builder: (context, state) => const SchoolManagementPage()),
          GoRoute(path: '/admin/cms', builder: (context, state) => const CmsManagementPage()),
          GoRoute(path: '/admin/subscriptions', builder: (context, state) => const SubscriptionManagementPage()),
          GoRoute(path: '/admin/performance', builder: (context, state) => const PlatformPerformancePage()),
          GoRoute(path: '/admin/broadcasts', builder: (context, state) => const NotificationBroadcastPage()),
          GoRoute(path: '/admin/watch-hours', builder: (context, state) => const WatchHoursPage()),

          // Principal (School Admin)
          GoRoute(path: '/principal/dashboard', builder: (context, state) => const PrincipalDashboard()),
          GoRoute(path: '/principal/classes', builder: (context, state) => const ClassroomManagementPage()),
          GoRoute(path: '/principal/teachers', builder: (context, state) => const TeacherManagementPage()),
          GoRoute(path: '/principal/attendance', builder: (context, state) => const AttendanceManagementPage()),
          GoRoute(path: '/principal/student-performance', builder: (context, state) => const StudentPerformancePage()),
          GoRoute(path: '/principal/class-performance', builder: (context, state) => const ClassPerformancePage()),
          GoRoute(path: '/principal/exam-results', builder: (context, state) => const ExamResultsPage()),

          // Teacher
          GoRoute(path: '/teacher/dashboard', builder: (context, state) => const TeacherDashboard()),
          GoRoute(path: '/teacher/quizzes', builder: (context, state) => const TeacherQuizManagementPage()),
          GoRoute(
            path: '/teacher/class/:classId/roster',
            builder: (context, state) => ClassRosterPage(classId: int.parse(state.pathParameters['classId'] ?? '0')),
          ),
          GoRoute(path: '/teacher/library', builder: (context, state) => const TeacherContentLibraryPage()),
          GoRoute(path: '/teacher/analytics', builder: (context, state) => const PerformanceOverview()),
          GoRoute(path: '/teacher/attendance', builder: (context, state) => const TeacherAttendancePage()),
          GoRoute(path: '/teacher/exams', builder: (context, state) => const ExamManagementPage()),

          // Student
          GoRoute(path: '/student/dashboard', builder: (context, state) => const StudentDashboard()),
          GoRoute(
            path: '/student/subject/:subjectId',
            builder: (context, state) => SubjectChaptersPage(
              subjectId: int.parse(state.pathParameters['subjectId'] ?? '0'),
              subjectName: state.uri.queryParameters['name'] ?? 'Subject',
            ),
          ),

          // Parent
          GoRoute(path: '/parent/dashboard', builder: (context, state) => const ParentDashboard()),

          // Shared
          GoRoute(
            path: '/ranking/:quizId/:classId',
            builder: (context, state) => RankingPage(
              quizId: int.parse(state.pathParameters['quizId'] ?? '0'),
              classId: int.parse(state.pathParameters['classId'] ?? '0'),
            ),
          ),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsPage()),
        ],
      ),

      // ── Standalone routes (no shell) ──
      GoRoute(
        path: '/quiz/:quizId',
        builder: (context, state) => QuizPage(quizId: int.parse(state.pathParameters['quizId'] ?? '0')),
      ),
      GoRoute(
        path: '/presentation/:videoId',
        builder: (context, state) => PresentationPlayerPage(
          videoId: int.parse(state.pathParameters['videoId'] ?? '0'),
          title: state.uri.queryParameters['title'] ?? 'Lesson',
          videoUrl: state.uri.queryParameters['url'] ?? '',
          thumbnailUrl: state.uri.queryParameters['thumb'] ?? '',
          durationSecs: int.tryParse(state.uri.queryParameters['duration'] ?? '0') ?? 0,
        ),
      ),
    ],
  );
}
