import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/remedy_service.dart';
import '../services/comment_service.dart';
import '../services/groq_service.dart';
import '../services/collection_service.dart';
import '../services/publication_service.dart';
import '../models/user_profile.dart';
import '../models/remedy.dart';
import '../models/comment.dart';
import '../models/ai_analysis.dart';
import '../models/user_collection.dart';
import '../models/publication.dart';

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
  final results = await ref.read(remedyServiceProvider).search(query);
  return _premiumFirst(results);
});

final userRatingProvider =
    FutureProvider.autoDispose.family<int?, String>((ref, remedyId) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return ref.read(remedyServiceProvider).getUserRating(remedyId, user.uid);
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

// ── Profil public ─────────────────────────────────────────────────────────────

final publicUserProfileProvider =
    FutureProvider.autoDispose.family<UserProfile?, String>((ref, uid) {
  return ref.read(authServiceProvider).fetchProfile(uid);
});

final publicUserRemediesProvider =
    FutureProvider.autoDispose.family<List<Remedy>, String>((ref, uid) async {
  final remedies = await ref.read(remedyServiceProvider).getUserRemedies(uid);
  return remedies.where((r) => !r.isPrivate).toList();
});

final publicUserCollectionsProvider =
    StreamProvider.autoDispose.family<List<UserCollection>, String>((ref, uid) {
  return ref.watch(collectionServiceProvider).watchCollections(uid);
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

List<Remedy> _premiumFirst(List<Remedy> items) {
  final premium = items.where((r) => r.authorIsPremium).toList();
  final regular = items.where((r) => !r.authorIsPremium).toList();
  return [...premium, ...regular];
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
      items: _premiumFirst(page.items),
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
        items: _premiumFirst([...current.items, ...page.items]),
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

// ── Publications ──────────────────────────────────────────────────────────────

final publicationServiceProvider =
    Provider<PublicationService>((ref) => PublicationService());

final publicationsProvider = StreamProvider<List<Publication>>((ref) {
  return ref.watch(publicationServiceProvider).watchAll();
});

final publicationByIdProvider =
    FutureProvider.autoDispose.family<Publication?, String>((ref, id) {
  return ref.read(publicationServiceProvider).getById(id);
});

// ── IA (Groq) ─────────────────────────────────────────────────────────────────

final groqServiceProvider = Provider<GroqService>((ref) => GroqService());

final remedyAnalysisProvider =
    StreamProvider.autoDispose.family<AiAnalysis?, String>((ref, remedyId) {
  return ref.read(groqServiceProvider).watchRemedyAnalysis(remedyId);
});

