/// EduCinema LMS — App Router
/// Role-aware GoRouter with shell navigation and all feature routes.
library;

import 'package:go_router/go_router.dart';

import '../../features/auth/view/login_page.dart';
import '../../features/auth/view/splash_page.dart';
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
import '../../features/student/view/chapter_videos_page.dart';
import '../../features/student/view/quiz_page.dart';
import '../../features/student/view/student_tests_page.dart';
import '../../features/student/view/test_taking_page.dart';
import '../../features/parent/view/parent_dashboard.dart';
import '../../features/ranking/view/ranking_page.dart';
import '../../features/notifications/view/notifications_page.dart';
import '../../features/attendance/view/attendance_management_page.dart';
import '../../features/teacher/view/teacher_attendance_page.dart';
import '../../features/teacher/view/exam_management_page.dart';
import '../../features/principal/view/exam_results_page.dart';
import '../../features/principal/view/salary_management_page.dart';
import '../../features/principal/view/fee_management_page.dart';
import '../../features/super_admin/view/school_management_page.dart';
import '../../features/super_admin/view/cms_management_page.dart';
import '../../features/super_admin/view/subscription_management_page.dart';
import '../../features/super_admin/view/platform_performance_page.dart';
import '../../features/super_admin/view/notification_broadcast_page.dart';
import '../../features/super_admin/view/watch_hours_page.dart';
import '../../features/super_admin/view/content_access_control_page.dart';
import '../../features/student/view/student_attendance_page.dart';
import '../../features/student/view/student_homework_page.dart';
import '../../features/student/view/student_fee_status_page.dart';
import '../../features/teacher/view/teacher_homework_page.dart';
import '../../features/teacher/view/teacher_salary_page.dart';
import '../../features/principal/view/timetable_management_page.dart';
import '../../features/student/view/student_timetable_page.dart';
import '../../features/teacher/view/teacher_schedule_page.dart';
import '../../features/student/view/student_exam_results_page.dart';
import '../../features/parent/view/parent_exam_results_page.dart';
import '../../features/messaging/view/conversation_list_page.dart';
import '../../features/messaging/view/conversation_detail_page.dart';
import '../../features/messaging/view/new_conversation_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // ── Root Redirect ──
      GoRoute(
        path: '/',
        redirect: (context, state) => '/splash',
      ),
      // ── Auth ──
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
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
          GoRoute(path: '/admin/content-access', builder: (context, state) => const ContentAccessControlPage()),

          // Principal (School Admin)
          GoRoute(path: '/principal/dashboard', builder: (context, state) => const PrincipalDashboard()),
          GoRoute(path: '/principal/classes', builder: (context, state) => const ClassroomManagementPage()),
          GoRoute(path: '/principal/teachers', builder: (context, state) => const TeacherManagementPage()),
          GoRoute(path: '/principal/attendance', builder: (context, state) => const AttendanceManagementPage()),
          GoRoute(path: '/principal/student-performance', builder: (context, state) => const StudentPerformancePage()),
          GoRoute(path: '/principal/class-performance', builder: (context, state) => const ClassPerformancePage()),
          GoRoute(path: '/principal/exam-results', builder: (context, state) => const ExamResultsPage()),
          GoRoute(path: '/principal/salaries', builder: (context, state) => const SalaryManagementPage()),
          GoRoute(path: '/principal/fees', builder: (context, state) => const FeeManagementPage()),
          GoRoute(path: '/principal/timetable', builder: (context, state) => const TimetableManagementPage()),

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
          GoRoute(path: '/teacher/homework', builder: (context, state) => const TeacherHomeworkPage()),
          GoRoute(path: '/teacher/salary', builder: (context, state) => const TeacherSalaryPage()),
          GoRoute(path: '/teacher/schedule', builder: (context, state) => const TeacherSchedulePage()),

          // Student
          GoRoute(path: '/student/dashboard', builder: (context, state) => const StudentDashboard()),
          GoRoute(
            path: '/student/subject/:subjectId',
            builder: (context, state) => SubjectChaptersPage(
              subjectId: int.parse(state.pathParameters['subjectId'] ?? '0'),
              subjectName: state.uri.queryParameters['name'] ?? 'Subject',
            ),
          ),
          GoRoute(
            path: '/student/chapter/:chapterId',
            builder: (context, state) => ChapterVideosPage(
              chapterId: int.parse(state.pathParameters['chapterId'] ?? '0'),
              chapterTitle: state.uri.queryParameters['title'] ?? 'Chapter',
            ),
          ),

          GoRoute(path: '/student/attendance', builder: (context, state) => const StudentAttendancePage()),
          GoRoute(path: '/student/homework', builder: (context, state) => const StudentHomeworkPage()),
          GoRoute(path: '/student/fees', builder: (context, state) => const StudentFeeStatusPage()),
          GoRoute(path: '/student/timetable', builder: (context, state) => const StudentTimetablePage()),
          GoRoute(path: '/student/exam-results', builder: (context, state) => const StudentExamResultsPage()),
          GoRoute(path: '/student/tests', builder: (context, state) => const StudentTestsPage()),

          // Parent
          GoRoute(path: '/parent/dashboard', builder: (context, state) => const ParentDashboard()),
          GoRoute(path: '/parent/exam-results', builder: (context, state) => const ParentExamResultsPage()),

          // Shared
          GoRoute(
            path: '/ranking/:quizId/:classId',
            builder: (context, state) => RankingPage(
              quizId: int.parse(state.pathParameters['quizId'] ?? '0'),
              classId: int.parse(state.pathParameters['classId'] ?? '0'),
            ),
          ),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsPage()),

          // Messaging
          GoRoute(path: '/messaging', builder: (context, state) => const ConversationListPage()),
          GoRoute(path: '/messaging/new', builder: (context, state) => const NewConversationPage()),
          GoRoute(
            path: '/messaging/:conversationId',
            builder: (context, state) => ConversationDetailPage(
              conversationId: int.parse(state.pathParameters['conversationId'] ?? '0'),
            ),
          ),
        ],
      ),

      // ── Standalone routes (no shell) ──
      GoRoute(
        path: '/quiz/:quizId',
        builder: (context, state) => QuizPage(quizId: int.parse(state.pathParameters['quizId'] ?? '0')),
      ),
      GoRoute(
        path: '/student/test-taking/:sessionId',
        builder: (context, state) => TestTakingPage(sessionId: int.parse(state.pathParameters['sessionId'] ?? '0')),
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
