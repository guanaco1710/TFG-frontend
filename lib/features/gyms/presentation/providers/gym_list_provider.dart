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

  GymListLoadState get state => _state;
  List<Gym> get gyms => _gyms;
  String? get errorMessage => _errorMessage;

  Future<void> loadGyms() async {
    _state = GymListLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.fetchGyms();
      _gyms = page.content;
      _state = GymListLoadState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = GymListLoadState.error;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _state = GymListLoadState.error;
    } finally {
      notifyListeners();
    }
  }
}
