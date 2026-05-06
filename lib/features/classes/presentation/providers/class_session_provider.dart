import 'package:flutter/foundation.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';
import 'package:tfg_frontend/features/classes/data/repositories/class_session_repository.dart';

enum ClassSessionLoadState { initial, loading, loaded, error }

class ClassSessionProvider extends ChangeNotifier {
  ClassSessionProvider({required ClassSessionRepository repository})
    : _repository = repository;

  final ClassSessionRepository _repository;

  ClassSessionLoadState _state = ClassSessionLoadState.initial;
  List<ClassSession> _sessions = [];
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int? _gymId;

  ClassSessionLoadState get state => _state;
  List<ClassSession> get sessions => _sessions;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  int? get gymId => _gymId;

  Future<void> loadSessionsByDay(DateTime day, {int? gymId}) async {
    _gymId = gymId;
    _state = ClassSessionLoadState.loading;
    _sessions = [];
    _hasMore = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final from = DateTime.utc(day.year, day.month, day.day, 0, 0, 0);
      final to = DateTime.utc(day.year, day.month, day.day, 23, 59, 59);
      _sessions = await _repository.fetchSchedule(from: from, to: to, gymId: gymId);
      _state = ClassSessionLoadState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ClassSessionLoadState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ClassSessionLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadSessions({int? gymId}) async {
    _gymId = gymId;
    _state = ClassSessionLoadState.loading;
    _sessions = [];
    _currentPage = 0;
    _hasMore = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.fetchSessions(gymId: gymId, page: 0);
      _sessions = page.content;
      _hasMore = page.hasMore;
      _currentPage = 0;
      _state = ClassSessionLoadState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ClassSessionLoadState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ClassSessionLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> refreshSessionsByDay(DateTime day, {int? gymId}) async {
    try {
      final from = DateTime.utc(day.year, day.month, day.day, 0, 0, 0);
      final to = DateTime.utc(day.year, day.month, day.day, 23, 59, 59);
      _sessions = await _repository.fetchSchedule(from: from, to: to, gymId: gymId ?? _gymId);
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _repository.fetchSessions(
        gymId: _gymId,
        page: _currentPage + 1,
      );
      _sessions = [..._sessions, ...page.content];
      _hasMore = page.hasMore;
      _currentPage++;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
