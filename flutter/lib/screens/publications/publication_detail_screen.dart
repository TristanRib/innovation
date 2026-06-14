import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/publication.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/web_app_bar.dart';

class PublicationDetailScreen extends StatelessWidget {
  final Publication publication;
  const PublicationDetailScreen({super.key, required this.publication});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const WebAppBar(title: Text('Article')),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 48),
          children: [
            _ArticleHeader(pub: publication),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: publication.sections
                    .map((s) => _SectionWidget(section: s))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── En-tête de l'article ──────────────────────────────────────────────────────

class _ArticleHeader extends StatelessWidget {
  final Publication pub;
  const _ArticleHeader({required this.pub});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMMM y', 'fr_FR').format(pub.publishedAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bannière image ou placeholder coloré
        if (pub.imageUrl != null)
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.network(
              pub.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _HeaderBanner(),
            ),
          )
        else
          _HeaderBanner(),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags
              if (pub.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: pub.tags
                      .map((t) => _TagChip(tag: t))
                      .toList(),
                ),
              if (pub.tags.isNotEmpty) const SizedBox(height: 12),

              // Titre
              Text(
                pub.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 10),

              // Résumé
              Text(
                pub.summary,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
              ),
              const SizedBox(height: 16),

              // Méta (auteur, date, durée)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.spa,
                        size: 14, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pub.authorName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.schedule_outlined,
                      size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${pub.readingTimeMinutes} min de lecture',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.menu_book_rounded,
            size: 48, color: AppColors.primaryDark),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Rendu des sections ────────────────────────────────────────────────────────

class _SectionWidget extends StatelessWidget {
  final PublicationSection section;
  const _SectionWidget({required this.section});

  @override
  Widget build(BuildContext context) {
    switch (section.type) {
      case 'heading':
        return Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            section.content ?? '',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
          ),
        );

      case 'paragraph':
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            section.content ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.65,
                  color: AppColors.textPrimary,
                ),
          ),
        );

      case 'bullets':
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: section.items.map((item) => _BulletItem(text: item)).toList(),
          ),
        );

      case 'tip':
        return _CalloutBox(
          icon: Icons.lightbulb_outline_rounded,
          color: const Color(0xFF4CAF50),
          backgroundColor: const Color(0xFFF1F8E9),
          content: section.content ?? '',
          context: context,
        );

      case 'warning':
        return _CalloutBox(
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
          backgroundColor: const Color(0xFFFFF8E1),
          content: section.content ?? '',
          context: context,
        );

      case 'quote':
        return _QuoteBlock(text: section.content ?? '', context: context);

      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            section.content ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.65),
          ),
        );
    }
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Icon(Icons.fiber_manual_record,
                size: 6, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalloutBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String content;
  final BuildContext context;
  const _CalloutBox({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.content,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  final String text;
  final BuildContext context;
  const _QuoteBlock({required this.text, required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
        color: AppColors.primaryLight.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}
