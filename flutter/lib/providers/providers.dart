import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/remedy_service.dart';
import '../services/comment_service.dart';
import '../services/groq_service.dart';
import '../services/collection_service.dart';
import '../models/user_profile.dart';
import '../models/remedy.dart';
import '../models/comment.dart';
import '../models/ai_analysis.dart';
import '../models/user_collection.dart';

// ── Services ──────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final remedyServiceProvider = Provider<RemedyService>((ref) => RemedyService());
final commentServiceProvider = Provider<CommentService>((ref) => CommentService());
final collectionServiceProvider = Provider<CollectionService>((ref) => CollectionService());

// ── Auth ──────────────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return ref.read(authServiceProvider).fetchProfile(user.uid);
});

// ── Remedies ──────────────────────────────────────────────────────────────────

final selectedTagProvider = StateProvider<String?>((ref) => null);
final sortByProvider = StateProvider<RemediaSortBy>((ref) => RemediaSortBy.newest);
final searchQueryProvider = StateProvider<String>((ref) => '');

final remediesProvider = StreamProvider<List<Remedy>>((ref) {
  final tag = ref.watch(selectedTagProvider);
  final sort = ref.watch(sortByProvider);
  return ref.watch(remedyServiceProvider).watchRemedies(tag: tag, sortBy: sort);
});

final searchResultsProvider = FutureProvider.autoDispose<List<Remedy>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  return ref.read(remedyServiceProvider).search(query);
});

final userRatingProvider =
    FutureProvider.autoDispose.family<int?, String>((ref, remedyId) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return ref.read(remedyServiceProvider).getUserRating(remedyId, user.uid);
});

final favoritesProvider = FutureProvider.autoDispose<List<Remedy>>((ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  if (profile == null) return [];
  return ref.read(remedyServiceProvider).getFavorites(profile.favoriteRemedyIds);
});

final userRemediesProvider = FutureProvider.autoDispose<List<Remedy>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  return ref.read(remedyServiceProvider).getUserRemedies(user.uid);
});

// ── Comments ──────────────────────────────────────────────────────────────────

final commentsProvider =
    StreamProvider.autoDispose.family<List<Comment>, String>((ref, remedyId) {
  return ref.watch(commentServiceProvider).watchComments(remedyId);
});

// ── Remedy by ID ──────────────────────────────────────────────────────────────

final remedyByIdProvider =
    FutureProvider.autoDispose.family<Remedy?, String>((ref, id) async {
  return ref.read(remedyServiceProvider).getById(id);
});

// ── Feed paginé ───────────────────────────────────────────────────────────────

class RemedyFeedState {
  final List<Remedy> items;
  final bool hasMore;
  final bool loadingMore;
  const RemedyFeedState({
    required this.items,
    this.hasMore = true,
    this.loadingMore = false,
  });
  RemedyFeedState copyWith({
    List<Remedy>? items,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      RemedyFeedState(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

class RemedyFeedNotifier extends AsyncNotifier<RemedyFeedState> {
  RemedyPage? _lastPage;

  @override
  Future<RemedyFeedState> build() async {
    _lastPage = null;
    final tag = ref.watch(selectedTagProvider);
    final sort = ref.watch(sortByProvider);
    final page = await ref.read(remedyServiceProvider).fetchPage(tag: tag, sortBy: sort);
    _lastPage = page;
    return RemedyFeedState(
      items: page.items,
      hasMore: page.items.length >= kPageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final tag = ref.read(selectedTagProvider);
      final sort = ref.read(sortByProvider);
      final page = await ref.read(remedyServiceProvider).fetchPage(
        tag: tag,
        sortBy: sort,
        cursor: _lastPage?.cursor,
      );
      _lastPage = page;
      state = AsyncData(RemedyFeedState(
        items: [...current.items, ...page.items],
        hasMore: page.items.length >= kPageSize,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}

final remedyFeedProvider =
    AsyncNotifierProvider<RemedyFeedNotifier, RemedyFeedState>(RemedyFeedNotifier.new);

// ── Collections ───────────────────────────────────────────────────────────────

final userCollectionsProvider = StreamProvider.autoDispose<List<UserCollection>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(collectionServiceProvider).watchCollections(user.uid);
});

// ── Alertes ───────────────────────────────────────────────────────────────────

final newRemediesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  if (profile == null || !profile.isPremium || profile.followedTags.isEmpty) return 0;
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final remedies = await ref
      .read(remedyServiceProvider)
      .getRemediesForTags(tags: profile.followedTags);
  return remedies.where((r) => r.createdAt.isAfter(cutoff)).length;
});

// ── IA (Groq) ─────────────────────────────────────────────────────────────────

final groqServiceProvider = Provider<GroqService>((ref) => GroqService());

final remedyAnalysisProvider =
    StreamProvider.autoDispose.family<AiAnalysis?, String>((ref, remedyId) {
  return ref.read(groqServiceProvider).watchRemedyAnalysis(remedyId);
});

