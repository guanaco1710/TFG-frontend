import 'package:flutter/foundation.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/membership_plans/data/models/membership_plan_models.dart';
import 'package:tfg_frontend/features/membership_plans/data/repositories/membership_plan_repository.dart';
import 'package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart';

enum PlansLoadState { initial, loading, loaded, error }

class GymPlansProvider extends ChangeNotifier {
  GymPlansProvider({
    required MembershipPlanRepository planRepository,
    required SubscriptionRepository subscriptionRepository,
  }) : _planRepo = planRepository,
       _subRepo = subscriptionRepository;

  final MembershipPlanRepository _planRepo;
  final SubscriptionRepository _subRepo;

  PlansLoadState _state = PlansLoadState.initial;
  List<MembershipPlan> _plans = [];
  String? _errorMessage;
  bool _isSubscribing = false;

  PlansLoadState get state => _state;
  List<MembershipPlan> get plans => _plans;
  String? get errorMessage => _errorMessage;
  bool get isSubscribing => _isSubscribing;

  Future<void> loadPlans() async {
    _state = PlansLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _plans = await _planRepo.fetchActivePlans();
      _state = PlansLoadState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = PlansLoadState.error;
    } catch (_) {
      _errorMessage = 'Ha ocurrido un error inesperado';
      _state = PlansLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> subscribe({
    required int membershipPlanId,
    required int gymId,
  }) async {
    _isSubscribing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _subRepo.subscribe(
        membershipPlanId: membershipPlanId,
        gymId: gymId,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Ha ocurrido un error inesperado';
      return false;
    } finally {
      _isSubscribing = false;
      notifyListeners();
    }
  }
}
