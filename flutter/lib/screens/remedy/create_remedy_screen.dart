import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medical_disclaimer.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/web_app_bar.dart';
import '../../core/constants.dart';

class CreateRemedyScreen extends ConsumerStatefulWidget {
  const CreateRemedyScreen({super.key});

  @override
  ConsumerState<CreateRemedyScreen> createState() => _CreateRemedyScreenState();
}

class _CreateRemedyScreenState extends ConsumerState<CreateRemedyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _methodCtrl = TextEditingController();
  final _ingredientCtrl = TextEditingController();

  final List<String> _ingredients = [];
  final Set<String> _selectedTags = {};
  bool _loading = false;
  bool _isPrivate = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _methodCtrl.dispose();
    _ingredientCtrl.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final v = _ingredientCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _ingredients.add(v);
      _ingredientCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un ingrédient.')),
      );
      return;
    }
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins une catégorie.')),
      );
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final profile = await ref.read(currentUserProfileProvider.future);

    setState(() => _loading = true);
    try {
      final remedy = await ref.read(remedyServiceProvider).createRemedy(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            ingredients: _ingredients,
            method: _methodCtrl.text.trim(),
            tags: _selectedTags.toList(),
            authorId: user.uid,
            authorName: profile?.pseudo ?? 'Anonyme',
            isPrivate: _isPrivate,
            authorIsPremium: profile?.isPremium ?? false,
          );
      ref.invalidate(remediesProvider);
      ref.invalidate(remedyFeedProvider);
      ref.invalidate(userRemediesProvider);
      ref.invalidate(currentUserProfileProvider);
      // ignore: unawaited_futures
      ref.read(groqServiceProvider).analyzeRemedy(remedy);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Remède partagé avec succès !')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium =
        ref.watch(currentUserProfileProvider).valueOrNull?.isPremium ?? false;

    return AppScaffold(
      appBar: const WebAppBar(title: Text('Partager un remède')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const MedicalDisclaimer(),
            const SizedBox(height: 20),

            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre du remède *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Pour quel symptôme ? Quel est l\'effet attendu ?',
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 20),

            Text('Ingrédients *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ingredientCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Miel, citron, gingembre…',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onFieldSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
            if (_ingredients.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _ingredients
                    .map((ing) => Chip(
                          label: Text(ing),
                          onDeleted: () => setState(() => _ingredients.remove(ing)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),

            TextFormField(
              controller: _methodCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Préparation *',
                hintText: 'Décrivez étape par étape comment préparer ce remède.',
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 20),

            Text('Catégories *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: kAvailableTags
                  .map((tag) => FilterChip(
                        label: Text(tag),
                        selected: _selectedTags.contains(tag),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        }),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _selectedTags.contains(tag)
                              ? Colors.white
                              : AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Toggle remède privé (premium uniquement)
            if (isPremium)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  value: _isPrivate,
                  onChanged: (v) => setState(() => _isPrivate = v),
                  title: const Text('Remède privé'),
                  subtitle: const Text('Visible uniquement par vous'),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_outline,
                        color: AppColors.primaryDark, size: 20),
                  ),
                  activeColor: AppColors.primary,
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Partager le remède'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
