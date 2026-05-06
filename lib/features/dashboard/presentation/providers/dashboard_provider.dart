import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';

enum DashboardState { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({required BookingRepository repository})
    : _repository = repository;

  final BookingRepository _repository;

  DashboardState _state = DashboardState.initial;
  List<Booking> _upcoming = [];
  String? _error;

  DashboardState get state => _state;
  List<Booking> get upcoming => _upcoming;
  String? get error => _error;

  Future<void> loadUpcoming() async {
    _state = DashboardState.loading;
    _error = null;
    notifyListeners();

    try {
      final from = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final page = await _repository.fetchMyBookings(
        page: 0,
        size: 3,
        status: BookingStatus.confirmed,
        from: from,
      );
      _upcoming = page.content;
      _state = DashboardState.loaded;
    } on ApiException catch (e) {
      _error = e.message;
      _state = DashboardState.error;
    } catch (e) {
      _error = e.toString();
      _state = DashboardState.error;
    } finally {
      notifyListeners();
    }
  }
}
