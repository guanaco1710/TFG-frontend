import 'package:flutter/foundation.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/auth/data/repositories/auth_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unauthenticated;
  AuthUser? _currentUser;
  String? _errorMessage;
  String? _refreshToken;

  AuthStatus get status => _status;
  AuthUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  Future<void> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.login(
        email: email,
        password: password,
      );
      _currentUser = response.user;
      _refreshToken = response.tokens.refreshToken;
      _status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      _currentUser = response.user;
      _refreshToken = response.tokens.refreshToken;
      _status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout({String? refreshToken}) async {
    final token = refreshToken ?? _refreshToken ?? '';
    await _repository.logout(refreshToken: token);
    _currentUser = null;
    _refreshToken = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final user = await _repository.restoreSession();
    if (user != null) {
      _currentUser = user;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
