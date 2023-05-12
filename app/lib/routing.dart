import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/chat/pages/chat_page.dart';
import 'package:acter/features/gallery/pages/gallery_page.dart';
import 'package:acter/features/home/pages/dashboard.dart';
import 'package:acter/features/home/pages/home_shell.dart';
import 'package:acter/features/news/pages/news_builder_page.dart';
import 'package:acter/features/news/pages/news_page.dart';
import 'package:acter/features/news/pages/post_page.dart';
import 'package:acter/features/news/pages/search_space_page.dart';
import 'package:acter/features/onboarding/pages/login_page.dart';
import 'package:acter/features/onboarding/pages/sign_up_page.dart';
import 'package:acter/features/profile/pages/social_profile_page.dart';
import 'package:acter/features/space/pages/overview_page.dart';
import 'package:acter/features/space/pages/shell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');
final GlobalKey<NavigatorState> _spaceNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'space');

final _routes = [
  GoRoute(
    name: 'login',
    path: '/login',
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    name: 'my-profile',
    path: '/profile',
    builder: (context, state) => const SocialProfilePage(),
  ),
  GoRoute(
    name: 'signup',
    path: '/signup',
    builder: (context, state) => const SignupPage(),
  ),
  GoRoute(
    path: '/gallery',
    builder: (context, state) => const GalleryPage(),
  ),
  GoRoute(
    name: 'bug-report',
    path: '/bug_report',
    builder: (context, state) =>
        BugReportPage(imagePath: state.queryParams['screenshot']),
  ),

  /// Application shell
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    pageBuilder: (context, state, child) {
      return NoTransitionPage(
        key: state.pageKey,
        child: HomeShell(child: child),
      );
    },
    routes: <RouteBase>[
      /// The first screen to display in the bottom navigation bar.
      GoRoute(
        parentNavigatorKey: _shellNavigatorKey,
        name: 'updates',
        path: '/updates',
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const NewsPage(),
          );
        },
        routes: <RouteBase>[
          GoRoute(
            parentNavigatorKey: _shellNavigatorKey,
            name: 'edit',
            path: 'edit',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: const NewsBuilderPage(),
              );
            },
          ),
          GoRoute(
            parentNavigatorKey: _shellNavigatorKey,
            name: 'post',
            path: 'post',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: PostPage(imgUri: state.extra as String?),
              );
            },
            routes: <RouteBase>[
              GoRoute(
                name: 'search-space',
                path: 'search_space',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const SearchSpacePage(),
                ),
              )
            ],
          ),
        ],
      ),

      GoRoute(
        name: 'chatroom',
        path: '/chat/:spaceId([!#][^/]+)', // !roomId, #roomName
        pageBuilder: (context, state) {
          return NoTransitionPage(key: state.pageKey, child: const ChatPage());
        },
      ),

      GoRoute(
        name: 'chat',
        path: '/chat',
        pageBuilder: (context, state) {
          return NoTransitionPage(key: state.pageKey, child: const ChatPage());
        },
      ),

      GoRoute(
        name: 'dashboard',
        path: '/dashboard',
        pageBuilder: (context, state) {
          return NoTransitionPage(key: state.pageKey, child: const Dashboard());
        },
      ),

      /// Space subshell
      ShellRoute(
        navigatorKey: _spaceNavigatorKey,
        pageBuilder: (context, state, child) {
          return NoTransitionPage(
            key: state.pageKey,
            child: SpaceShell(
              spaceIdOrAlias: state.params['spaceId']!,
              child: child,
            ),
          );
        },
        routes: <RouteBase>[
          GoRoute(
            name: 'space',
            path: '/:spaceId([!#][^/]+)', // !spaceId, #spaceName
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: SpaceOverview(spaceIdOrAlias: state.params['spaceId']!),
              );
            },
          ),
        ],
      ),

      GoRoute(
        path: '/',
        name: 'main',
        redirect: (BuildContext context, GoRouterState state) {
          final bool isDesktop =
              desktopPlatforms.contains(Theme.of(context).platform);
          if (isDesktop) {
            return '/dashboard';
          } else {
            return '/updates';
          }
        },
      ),
    ],
  ),
];

// GoRouter configuration
final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: _routes,
);

final goRouterProvider = Provider<GoRouter>(
  (ref) => router,
);
