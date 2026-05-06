import 'package:flutter/foundation.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/ratings/data/models/rating_models.dart';
import 'package:tfg_frontend/features/ratings/data/repositories/rating_repository.dart';

enum RatingLoadState { initial, loading, loaded, error }

class RatingProvider extends ChangeNotifier {
  RatingProvider({required RatingRepository repository})
      : _repository = repository;

  final RatingRepository _repository;
  RatingLoadState _state = RatingLoadState.initial;
  final Set<int> _ratedSessionIds = {};
  String? _errorMessage;
  String? _submitError;

  RatingLoadState get state => _state;
  Set<int> get ratedSessionIds => Set.unmodifiable(_ratedSessionIds);
  String? get errorMessage => _errorMessage;
  String? get submitError => _submitError;

  bool isRated(int sessionId) => _ratedSessionIds.contains(sessionId);

  Future<void> loadMyRatings() async {
    _state = RatingLoadState.loading;
    notifyListeners();
    try {
      final page = await _repository.fetchMyRatings();
      _ratedSessionIds
        ..clear()
        ..addAll(page.content.map((r) => r.sessionId));
      _errorMessage = null;
      _state = RatingLoadState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = RatingLoadState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _state = RatingLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<Rating?> submitRating({
    required int sessionId,
    required int score,
    String? comment,
  }) async {
    _submitError = null;
    try {
      final rating = await _repository.submitRating(
        sessionId: sessionId,
        score: score,
        comment: comment,
      );
      _ratedSessionIds.add(sessionId);
      notifyListeners();
      return rating;
    } on ApiException catch (e) {
      _submitError = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _submitError = e.toString();
      notifyListeners();
      return null;
    }
  }
}
