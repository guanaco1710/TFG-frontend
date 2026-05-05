import 'package:flutter/foundation.dart';
import 'package:tfg_frontend/core/exceptions/api_exception.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';

enum BookingLoadState { initial, loading, loaded, error }

class BookingProvider extends ChangeNotifier {
  BookingProvider({required BookingRepository repository})
    : _repository = repository;

  final BookingRepository _repository;

  BookingLoadState _state = BookingLoadState.initial;
  List<Booking> _bookings = [];
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  bool _isBooking = false;
  String? _bookingError;
  bool _isCancelling = false;

  BookingLoadState get state => _state;
  List<Booking> get bookings => _bookings;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  bool get isBooking => _isBooking;
  String? get bookingError => _bookingError;
  bool get isCancelling => _isCancelling;

  Future<void> loadMyBookings() async {
    _state = BookingLoadState.loading;
    _bookings = [];
    _currentPage = 0;
    _hasMore = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.fetchMyBookings(page: 0);
      _bookings = page.content;
      _hasMore = page.hasMore;
      _state = BookingLoadState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = BookingLoadState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _state = BookingLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _repository.fetchMyBookings(page: _currentPage + 1);
      _bookings = [..._bookings, ...page.content];
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

  Future<Booking?> book({required int classSessionId}) async {
    _isBooking = true;
    _bookingError = null;
    notifyListeners();

    try {
      final booking = await _repository.book(classSessionId: classSessionId);
      return booking;
    } on ApiException catch (e) {
      _bookingError = e.message;
      return null;
    } catch (e) {
      _bookingError = e.toString();
      return null;
    } finally {
      _isBooking = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking({required int bookingId}) async {
    _isCancelling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.cancelBooking(bookingId: bookingId);
      _bookings = [for (final b in _bookings) b.id == bookingId ? updated : b];
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
}
