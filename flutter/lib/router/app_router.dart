import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/remedy.dart';
import '../providers/providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/remedy/remedy_detail_screen.dart';
import '../screens/remedy/create_remedy_screen.dart';
import '../screens/profile/profile_screen.dart';

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
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/remedy/:id',
        builder: (context, state) {
          final remedy = state.extra as Remedy?;
          if (remedy == null) {
            return const Scaffold(
              body: Center(child: Text('Remède introuvable.')),
            );
          }
          return RemedyDetailScreen(remedy: remedy);
        },
      ),
      GoRoute(
        path: '/create',
        builder: (_, __) => const CreateRemedyScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page introuvable : ${state.error}')),
    ),
  );
});
