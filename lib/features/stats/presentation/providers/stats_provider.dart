import 'package:flutter/foundation.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/stats/data/models/stats_models.dart';
import 'package:tfg_frontend/features/stats/data/repositories/stats_repository.dart';

enum StatsLoadState { initial, loading, loaded, error }

class StatsProvider extends ChangeNotifier {
  StatsProvider({required StatsRepository repository})
    : _repository = repository;

  final StatsRepository _repository;

  StatsLoadState _state = StatsLoadState.initial;
  UserStats? _stats;
  String? _errorMessage;

  StatsLoadState get state => _state;
  UserStats? get stats => _stats;
  String? get errorMessage => _errorMessage;

  Future<void> loadStats() async {
    _state = StatsLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _repository.getMyStats();
      _state = StatsLoadState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = StatsLoadState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _state = StatsLoadState.error;
    } finally {
      notifyListeners();
    }
  }
}
