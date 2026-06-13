import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/remedy_service.dart';
import '../services/comment_service.dart';
import '../services/groq_service.dart';
import '../models/user_profile.dart';
import '../models/remedy.dart';
import '../models/comment.dart';
import '../models/ai_analysis.dart';

// ── Services ──────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final remedyServiceProvider = Provider<RemedyService>((ref) => RemedyService());
final commentServiceProvider = Provider<CommentService>((ref) => CommentService());

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

// ── IA (Groq) ─────────────────────────────────────────────────────────────────

final groqServiceProvider = Provider<GroqService>((ref) => GroqService());

final aiAnalysisProvider =
    FutureProvider.autoDispose.family<AiAnalysis, Remedy>((ref, remedy) async {
  return ref.read(groqServiceProvider).analyzeRemedy(remedy);
});
