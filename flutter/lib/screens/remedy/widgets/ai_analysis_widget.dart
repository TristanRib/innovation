import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/remedy.dart';
import '../../../models/ai_analysis.dart';
import '../../../providers/providers.dart';
import '../../../core/theme/app_theme.dart';

class AiAnalysisWidget extends ConsumerStatefulWidget {
  final Remedy remedy;
  const AiAnalysisWidget({super.key, required this.remedy});

  @override
  ConsumerState<AiAnalysisWidget> createState() => _AiAnalysisWidgetState();
}

class _AiAnalysisWidgetState extends ConsumerState<AiAnalysisWidget> {
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    if (!_requested) {
      return _TriggerButton(onTap: () => setState(() => _requested = true));
    }

    final analysisAsync = ref.watch(aiAnalysisProvider(widget.remedy));

    return analysisAsync.when(
      loading: () => const _LoadingCard(),
      error: (e, _) => _ErrorCard(error: e.toString()),
      data: (analysis) => _AnalysisCard(analysis: analysis),
    );
  }
}

// ── Bouton déclencheur ────────────────────────────────────────────────────────

class _TriggerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TriggerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.auto_awesome, size: 18),
      label: const Text('Analyse IA — effets & contre-indications'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}

// ── Chargement ────────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Text(
            'Analyse en cours…',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}

// ── Erreur ────────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Analyse indisponible. Vérifiez votre connexion.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte de résultat ─────────────────────────────────────────────────────────

class _AnalysisCard extends StatelessWidget {
  final AiAnalysis analysis;
  const _AnalysisCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Text(
                  'Analyse IA',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                _EvidenceBadge(level: analysis.evidenceLevel, color: analysis.evidenceColor),
                const SizedBox(width: 8),
                _SafetyBadge(score: analysis.safetyScore, color: analysis.safetyColor),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Résumé
                Text(analysis.summary, style: Theme.of(context).textTheme.bodyMedium),

                if (analysis.provenBenefits.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Section(
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.primary,
                    title: 'Effets documentés',
                    items: analysis.provenBenefits,
                  ),
                ],

                if (analysis.contraindications.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Section(
                    icon: Icons.warning_amber_outlined,
                    iconColor: AppColors.warning,
                    title: 'Contre-indications',
                    items: analysis.contraindications,
                  ),
                ],

                const SizedBox(height: 12),
                Text(
                  'Généré par IA — à titre informatif uniquement.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceBadge extends StatelessWidget {
  final String level;
  final Color color;
  const _EvidenceBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        level,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SafetyBadge extends StatelessWidget {
  final int score;
  final Color color;
  const _SafetyBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shield_outlined, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          '$score/5',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;

  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.fiber_manual_record, size: 7, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item, style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
