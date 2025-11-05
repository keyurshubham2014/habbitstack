import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/anchor_detection_service.dart';
import 'user_provider.dart';

// Anchor Detection Service Provider
final anchorDetectionServiceProvider = Provider<AnchorDetectionService>((ref) {
  return AnchorDetectionService();
});

// Anchor Candidates Provider
final anchorCandidatesProvider = FutureProvider<List<AnchorCandidate>>((ref) async {
  final service = ref.read(anchorDetectionServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  return await service.detectAnchorCandidates(user.id!);
});
