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
  List<Subscription> _subscriptions = [];
  String? _errorMessage;
  bool _isCancelling = false;

  SubscriptionLoadState get state => _state;
  List<Subscription> get subscriptions => _subscriptions;
  String? get errorMessage => _errorMessage;
  bool get isCancelling => _isCancelling;

  Future<bool> cancelSubscription({required int subscriptionId}) async {
    _isCancelling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.cancelSubscription(subscriptionId: subscriptionId);
      await loadMySubscriptions();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }

  Future<void> loadMySubscriptions() async {
    _state = SubscriptionLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscriptions = await _repository.fetchMySubscriptions();
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
