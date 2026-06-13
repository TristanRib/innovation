import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/user_profile.dart';
import '../../models/user_collection.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants.dart';
import '../../core/widgets/loading_widget.dart';
import '../remedy/widgets/remedy_card.dart';

const _kGrid = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 380,
  mainAxisExtent: 258,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
);

void _showEditPseudoDialog(BuildContext context, WidgetRef ref, String current) {
  final ctrl = TextEditingController(text: current);
  bool loading = false;
  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Modifier le pseudo'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Pseudo'),
          enabled: !loading,
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: loading
                ? null
                : () async {
                    final uid = ref.read(authStateProvider).valueOrNull?.uid;
                    if (uid == null || ctrl.text.trim().isEmpty) return;
                    setState(() => loading = true);
                    try {
                      await ref
                          .read(authServiceProvider)
                          .updatePseudo(uid, ctrl.text.trim());
                      ref.invalidate(currentUserProfileProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (_) {
                      setState(() => loading = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Impossible de modifier le pseudo.')),
                        );
                      }
                    }
                  },
            child: loading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Sauvegarder'),
          ),
        ],
      ),
    ),
  ).then((_) => ctrl.dispose());
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    return profileAsync.when(
      loading: () => const LoadingOverlay(),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (profile) {
        if (profile == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline, size: 56, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text('Vous n\'êtes pas connecté',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          );
        }
        return _ProfileContent(profile: profile);
      },
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final UserProfile profile;
  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeader(profile: profile),
          const TabBar(
            tabs: [
              Tab(text: 'Mes remèdes'),
              Tab(text: 'Favoris'),
              Tab(text: 'Collections'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _UserRemediesTab(),
                _FavoritesTab(),
                _CollectionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final UserProfile profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + infos + logout
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Text(
                  profile.pseudo.isNotEmpty ? profile.pseudo[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(profile.pseudo,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 4),
                        if (profile.isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.spa, color: Colors.white, size: 11),
                                SizedBox(width: 4),
                                Text('Premium',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 15, color: AppColors.textTertiary),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              _showEditPseudoDialog(context, widgetRef, profile.pseudo),
                        ),
                      ],
                    ),
                    Text(profile.email,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis),
                    Text(
                      'Membre depuis ${DateFormat('MMM yyyy').format(profile.createdAt)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              // Logout
              IconButton(
                icon: const Icon(Icons.logout_outlined,
                    size: 20, color: AppColors.textSecondary),
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
                    await widgetRef.read(authServiceProvider).logout();
                    if (context.mounted) context.go('/');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stats
          Row(
            children: [
              _StatPill(
                icon: Icons.spa,
                label: '${profile.createdRemediesCount} remèdes',
              ),
              const SizedBox(width: 10),
              _StatPill(
                icon: Icons.favorite,
                label: '${profile.favoriteRemedyIds.length} favoris',
              ),
            ],
          ),

          // Alertes tags (premium only)
          if (profile.isPremium) _FollowedTagsSection(profile: profile),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

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
          Icon(icon, size: 14, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _UserRemediesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remediesAsync = ref.watch(userRemediesProvider);
    return remediesAsync.when(
      loading: () => const LoadingOverlay(),
      error: (e, _) => Center(child: Text('$e')),
      data: (remedies) => remedies.isEmpty
          ? _EmptyTab(
              icon: Icons.spa_outlined,
              message: 'Vous n\'avez pas encore partagé de remède.',
              actionLabel: 'Partager maintenant',
              onAction: () => context.push('/create'),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              gridDelegate: _kGrid,
              itemCount: remedies.length,
              itemBuilder: (_, i) => RemedyCard(remedy: remedies[i]),
            ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    return favoritesAsync.when(
      loading: () => const LoadingOverlay(),
      error: (e, _) => Center(child: Text('$e')),
      data: (remedies) => remedies.isEmpty
          ? const _EmptyTab(
              icon: Icons.favorite_outline,
              message: 'Aucun remède en favori.',
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              gridDelegate: _kGrid,
              itemCount: remedies.length,
              itemBuilder: (_, i) => RemedyCard(remedy: remedies[i]),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: AppColors.textTertiary),
            const SizedBox(height: 14),
            Text(message,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Collections tab ──────────────────────────────────────────────────────────

class _CollectionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(userCollectionsProvider);
    return collectionsAsync.when(
      loading: () => const LoadingOverlay(),
      error: (e, _) => Center(child: Text('$e')),
      data: (collections) {
        if (collections.isEmpty) {
          return const _EmptyTab(
            icon: Icons.collections_bookmark_outlined,
            message: 'Aucune collection pour l\'instant.\nAjoutez des remèdes depuis leur page détail.',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisExtent: 110,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: collections.length,
          itemBuilder: (_, i) => _CollectionCard(collection: collections[i]),
        );
      },
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final UserCollection collection;
  const _CollectionCard({required this.collection});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/collection/${collection.id}', extra: collection),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bookmark, size: 18, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    collection.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${collection.remedyIds.length} remède${collection.remedyIds.length > 1 ? 's' : ''}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Followed tags section (premium, inside _ProfileHeader) ───────────────────

class _FollowedTagsSection extends ConsumerWidget {
  final UserProfile profile;
  const _FollowedTagsSection({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = Set<String>.from(profile.followedTags);

    Future<void> toggleTag(String tag) async {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) return;
      final updated = Set<String>.from(followed);
      if (updated.contains(tag)) {
        updated.remove(tag);
      } else {
        updated.add(tag);
      }
      await ref.read(authServiceProvider).updateFollowedTags(uid, updated.toList());
      ref.invalidate(currentUserProfileProvider);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.notifications_outlined, size: 16, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Text('Alertes par catégorie',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: kAvailableTags.map((tag) {
            final isOn = followed.contains(tag);
            return FilterChip(
              label: Text(tag, style: const TextStyle(fontSize: 12)),
              selected: isOn,
              onSelected: (_) => toggleTag(tag),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isOn ? Colors.white : AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }
}
