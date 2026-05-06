import 'package:flutter/foundation.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/classes/data/models/class_session_models.dart';
import 'package:tfg_frontend/features/classes/data/repositories/class_session_repository.dart';

enum SessionRosterState { initial, loading, loaded, error }

class SessionRosterProvider extends ChangeNotifier {
  SessionRosterProvider({required ClassSessionRepository repository})
      : _repository = repository;

  final ClassSessionRepository _repository;

  SessionRosterState _state = SessionRosterState.initial;
  List<RosterEntry> _entries = [];
  String? _errorMessage;
  int? _sessionId;

  SessionRosterState get state => _state;
  List<RosterEntry> get entries => _entries;
  String? get errorMessage => _errorMessage;

  Future<void> load(int sessionId) async {
    _sessionId = sessionId;
    _state = SessionRosterState.loading;
    _entries = [];
    _errorMessage = null;
    notifyListeners();

    try {
      _entries = await _repository.fetchRoster(sessionId);
      _state = SessionRosterState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = SessionRosterState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _state = SessionRosterState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> reload() async {
    if (_sessionId != null) await load(_sessionId!);
  }
}
