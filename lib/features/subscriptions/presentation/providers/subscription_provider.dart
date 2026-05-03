import 'package:flutter/foundation.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart';
import 'package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart';

enum SubscriptionLoadState { initial, loading, loaded, error }

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider({required SubscriptionRepository repository})
    : _repository = repository;

  final SubscriptionRepository _repository;

  SubscriptionLoadState _state = SubscriptionLoadState.initial;
  Subscription? _subscription;
  String? _errorMessage;

  SubscriptionLoadState get state => _state;
  Subscription? get subscription => _subscription;
  String? get errorMessage => _errorMessage;

  Future<void> loadMySubscription() async {
    _state = SubscriptionLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscription = await _repository.fetchMySubscription();
      _state = SubscriptionLoadState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = SubscriptionLoadState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _state = SubscriptionLoadState.error;
    } finally {
      notifyListeners();
    }
  }
}
