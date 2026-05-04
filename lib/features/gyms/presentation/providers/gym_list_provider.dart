import 'package:flutter/foundation.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/gyms/data/models/gym_models.dart';
import 'package:tfg_frontend/features/gyms/data/repositories/gym_repository.dart';

enum GymListLoadState { initial, loading, loaded, error }

class GymListProvider extends ChangeNotifier {
  GymListProvider({required GymRepository repository})
    : _repository = repository;

  final GymRepository _repository;

  GymListLoadState _state = GymListLoadState.initial;
  List<Gym> _gyms = [];
  String? _errorMessage;
  String _query = '';
  int _currentPage = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  GymListLoadState get state => _state;
  List<Gym> get gyms => _gyms;
  String get query => _query;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  List<Gym> get filteredGyms {
    if (_query.isEmpty) return _gyms;
    final q = _query.toLowerCase();
    return _gyms.where((g) => g.name.toLowerCase().contains(q)).toList();
  }

  set query(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> loadGyms() async {
    _state = GymListLoadState.loading;
    _gyms = [];
    _currentPage = 0;
    _hasMore = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.fetchGyms(page: 0);
      _gyms = page.content;
      _hasMore = page.hasMore;
      _state = GymListLoadState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = GymListLoadState.error;
    } catch (e) {
      _errorMessage = 'Ha ocurrido un error inesperado';
      _state = GymListLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _state != GymListLoadState.loaded) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _repository.fetchGyms(page: _currentPage + 1);
      _gyms = [..._gyms, ...page.content];
      _hasMore = page.hasMore;
      _currentPage++;
    } on ApiException catch (_) {
      // already-loaded items remain visible; silently swallow
    } catch (_) {
      // same
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
