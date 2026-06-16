import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/remedy.dart';
import '../providers/providers.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/main_shell.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/remedy/remedy_detail_screen.dart';
import '../screens/remedy/create_remedy_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/collection_detail_screen.dart';
import '../screens/profile/public_profile_screen.dart';
import '../screens/remedy/edit_remedy_screen.dart';
import '../screens/publications/publications_screen.dart';
import '../screens/publications/publication_detail_screen.dart';
import '../models/user_collection.dart';
import '../models/publication.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final protectedRoutes = ['/create', '/profile'];
      final isGoingToProtected =
          protectedRoutes.any((r) => state.matchedLocation.startsWith(r));
      if (!isLoggedIn && isGoingToProtected) return '/login';
      return null;
    },
    routes: [
      // ── Shell (bottom nav) ──────────────────────────────────────────────────
      ShellRoute(
        pageBuilder: (context, state, child) => NoTransitionPage(
          key: state.pageKey,
          child: MainShell(location: state.matchedLocation, child: child),
        ),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, state) =>
                NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (_, state) =>
                NoTransitionPage(key: state.pageKey, child: const SearchScreen()),
          ),
          GoRoute(
            path: '/publications',
            pageBuilder: (_, state) =>
                NoTransitionPage(key: state.pageKey, child: const PublicationsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, state) =>
                NoTransitionPage(key: state.pageKey, child: const ProfileScreen()),
          ),
        ],
      ),
      // ── Standalone (full screen, no bottom nav) ─────────────────────────────
      GoRoute(
        path: '/user/:uid',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: PublicProfileScreen(uid: state.pathParameters['uid']!),
        ),
      ),
      GoRoute(
        path: '/publication/:id',
        pageBuilder: (context, state) {
          final pub = state.extra as Publication?;
          final id = state.pathParameters['id']!;
          return NoTransitionPage(
            key: state.pageKey,
            child: pub != null
                ? PublicationDetailScreen(publication: pub)
                : _PublicationLoader(id: id),
          );
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const RegisterScreen()),
      ),
      GoRoute(
        path: '/create',
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const CreateRemedyScreen()),
      ),
      GoRoute(
        path: '/collection/:id',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: CollectionDetailScreen(collection: state.extra as UserCollection),
        ),
      ),
      GoRoute(
        path: '/edit-remedy',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: EditRemedyScreen(remedy: state.extra as Remedy),
        ),
      ),
      GoRoute(
        path: '/remedy/:id',
        pageBuilder: (context, state) {
          final remedy = state.extra as Remedy?;
          final id = state.pathParameters['id']!;
          return NoTransitionPage(
            key: state.pageKey,
            child: remedy != null
                ? RemedyDetailScreen(remedy: remedy)
                : _RemedyLoader(id: id),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page introuvable : ${state.error}')),
    ),
  );
});

class _PublicationLoader extends ConsumerWidget {
  final String id;
  const _PublicationLoader({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicationByIdProvider(id));
    return async.when(
      loading: () => const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const AppScaffold(
        body: Center(child: Text('Publication introuvable.')),
      ),
      data: (pub) => pub == null
          ? const AppScaffold(body: Center(child: Text('Publication introuvable.')))
          : PublicationDetailScreen(publication: pub),
    );
  }
}

class _RemedyLoader extends ConsumerWidget {
  final String id;
  const _RemedyLoader({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRemedy = ref.watch(remedyByIdProvider(id));
    return asyncRemedy.when(
      loading: () => const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const AppScaffold(
        body: Center(child: Text('Remède introuvable.')),
      ),
      data: (remedy) => remedy == null
          ? const AppScaffold(body: Center(child: Text('Remède introuvable.')))
          : RemedyDetailScreen(remedy: remedy),
    );
  }
}
