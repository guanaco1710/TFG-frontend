import 'package:flutter/foundation.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/profile/data/models/user_profile_models.dart';
import 'package:tfg_frontend/features/profile/data/repositories/user_repository.dart';

enum ProfileLoadState { initial, loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required UserRepository repository})
    : _repository = repository;

  final UserRepository _repository;

  ProfileLoadState _state = ProfileLoadState.initial;
  UserProfile? _profile;
  String? _errorMessage;

  ProfileLoadState get state => _state;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _state = ProfileLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.getMe();
      _state = ProfileLoadState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ProfileLoadState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ProfileLoadState.error;
    } finally {
      notifyListeners();
    }
  }
}
