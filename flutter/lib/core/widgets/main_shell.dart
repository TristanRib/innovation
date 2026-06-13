import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'web_layout.dart';
import '../../providers/providers.dart';
import '../../models/user_profile.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  final String location;
  const MainShell({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authStateProvider).valueOrNull != null;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final newRemediesCount = ref.watch(newRemediesCountProvider).valueOrNull ?? 0;

    int selectedIndex = 0;
    if (location.startsWith('/search')) selectedIndex = 1;
    if (location.startsWith('/profile')) selectedIndex = 2;

    return SelectionArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Header app (pleine largeur, contenu contraint) ──────────────
              Material(
                color: AppColors.surface,
                elevation: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WebLayout(
                      child: _AppHeader(isLoggedIn: isLoggedIn, profile: profile),
                    ),
                    const Divider(height: 1, thickness: 0.5),
                  ],
                ),
              ),
              // ── Contenu de la page ──────────────────────────────────────────
              Expanded(
                child: WebLayout(child: child),
              ),
            ],
          ),
        ),
        // ── Navigation bar (pleine largeur, contenu contraint) ─────────────
        bottomNavigationBar: Container(
          color: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1, thickness: 0.5),
              WebLayout(
                child: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (i) {
                    switch (i) {
                      case 0:
                        context.go('/');
                      case 1:
                        context.go('/search');
                      case 2:
                        isLoggedIn ? context.go('/profile') : context.go('/login');
                    }
                  },
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore),
                      label: 'Découvrir',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search),
                      label: 'Recherche',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: newRemediesCount > 0,
                        label: Text('$newRemediesCount'),
                        child: Icon(isLoggedIn ? Icons.person_outline : Icons.login_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: newRemediesCount > 0,
                        label: Text('$newRemediesCount'),
                        child: Icon(isLoggedIn ? Icons.person : Icons.login),
                      ),
                      label: isLoggedIn ? 'Profil' : 'Connexion',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: isLoggedIn
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/create'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Partager'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  final bool isLoggedIn;
  final UserProfile? profile;
  const _AppHeader({required this.isLoggedIn, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
      child: Row(
        children: [
          Semantics(
            label: 'Remedia – accueil',
            button: true,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go('/'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.spa, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remedia',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          if (isLoggedIn && profile != null)
            Semantics(
              label: 'Mon profil',
              button: true,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      profile!.pseudo.isNotEmpty ? profile!.pseudo[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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
}
