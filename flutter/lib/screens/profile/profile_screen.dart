import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_widget.dart';
import '../remedy/widgets/remedy_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final userRemediesAsync = ref.watch(userRemediesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mon profil'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Se déconnecter',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Se déconnecter ?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Déconnecter')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authServiceProvider).logout();
                  if (context.mounted) context.go('/');
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.spa_outlined), text: 'Mes remèdes'),
              Tab(icon: Icon(Icons.favorite_outline), text: 'Favoris'),
            ],
          ),
        ),
        body: profileAsync.when(
          loading: () => const LoadingOverlay(),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (profile) {
            if (profile == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Vous n\'êtes pas connecté.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                // Header
                Container(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          profile.pseudo.isNotEmpty
                              ? profile.pseudo[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.pseudo,
                                style: Theme.of(context).textTheme.titleLarge),
                            Text(profile.email,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              'Membre depuis ${DateFormat('MMM yyyy').format(profile.createdAt)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditPseudoDialog(context, ref, profile.pseudo),
                      ),
                    ],
                  ),
                ),

                // Stats
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      _StatChip(
                        icon: Icons.spa,
                        label: '${profile.createdRemediesCount} remèdes',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.favorite,
                        label: '${profile.favoriteRemedyIds.length} favoris',
                      ),
                    ],
                  ),
                ),

                // Tabs content
                Expanded(
                  child: TabBarView(
                    children: [
                      userRemediesAsync.when(
                        loading: () => const LoadingOverlay(),
                        error: (e, _) => Center(child: Text('$e')),
                        data: (remedies) => remedies.isEmpty
                            ? _EmptyTab(
                                icon: Icons.spa_outlined,
                                message: 'Vous n\'avez pas encore partagé de remède.',
                                actionLabel: 'Partager un remède',
                                onAction: () => context.push('/create'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 8, bottom: 16),
                                itemCount: remedies.length,
                                itemBuilder: (_, i) => RemedyCard(remedy: remedies[i]),
                              ),
                      ),
                      favoritesAsync.when(
                        loading: () => const LoadingOverlay(),
                        error: (e, _) => Center(child: Text('$e')),
                        data: (remedies) => remedies.isEmpty
                            ? const _EmptyTab(
                                icon: Icons.favorite_outline,
                                message: 'Aucun remède en favori.',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 8, bottom: 16),
                                itemCount: remedies.length,
                                itemBuilder: (_, i) => RemedyCard(remedy: remedies[i]),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showEditPseudoDialog(BuildContext context, WidgetRef ref, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le pseudo'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Pseudo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final uid = ref.read(authStateProvider).valueOrNull?.uid;
              if (uid != null && ctrl.text.trim().isNotEmpty) {
                await ref.read(authServiceProvider).updatePseudo(uid, ctrl.text.trim());
                ref.invalidate(currentUserProfileProvider);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyTab({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.primaryLight),
          const SizedBox(height: 12),
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
