import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tfg_frontend/core/exceptions/api_exception.dart';
import 'package:tfg_frontend/features/notifications/data/models/notification_models.dart';
import 'package:tfg_frontend/features/notifications/data/repositories/notification_repository.dart';

enum NotificationState { idle, loading, loaded, error }

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required NotificationRepository repository})
    : _repository = repository {
    loadPage(0);
    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _pollUnreadCount(),
    );
  }

  final NotificationRepository _repository;

  NotificationState _state = NotificationState.idle;
  List<AppNotification> _notifications = [];
  int _totalPages = 0;
  int _currentPage = 0;
  int _unreadCount = 0;
  String? _error;
  Timer? _timer;
  bool _hasMore = false;

  NotificationState get state => _state;
  List<AppNotification> get notifications => _notifications;
  int get totalPages => _totalPages;
  int get currentPage => _currentPage;
  int get unreadCount => _unreadCount;
  String? get error => _error;
  bool get hasMore => _hasMore;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadPage(int page) async {
    _state = NotificationState.loading;
    if (page == 0) {
      _notifications = [];
    }
    _error = null;
    notifyListeners();

    try {
      final result = await Future.wait([
        _repository.fetchNotifications(page: page),
        if (page == 0) _repository.fetchUnreadCount(),
      ]);

      final notificationPage = result[0] as NotificationPage;
      if (page == 0) {
        _notifications = notificationPage.content;
        _unreadCount = result[1] as int;
      } else {
        _notifications = [..._notifications, ...notificationPage.content];
      }
      _totalPages = notificationPage.totalPages;
      _currentPage = notificationPage.page;
      _hasMore = notificationPage.hasMore;
      _state = NotificationState.loaded;
    } on ApiException catch (e) {
      _error = e.message;
      _state = NotificationState.error;
    } catch (_) {
      _error = 'Error de conexión. Inténtalo de nuevo.';
      _state = NotificationState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (!_hasMore) return;
    await loadPage(_currentPage + 1);
  }

  Future<void> markRead(int id) async {
    try {
      await _repository.markRead(id);
      _notifications = [
        for (final n in _notifications)
          n.id == id ? n.copyWith(read: true) : n,
      ];
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    } on ApiException {
      // swallow — the item visually stays unread
    } catch (_) {
      // swallow
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
      _notifications = [for (final n in _notifications) n.copyWith(read: true)];
      _unreadCount = 0;
      notifyListeners();
    } on ApiException {
      // swallow
    } catch (_) {
      // swallow
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.delete(id);
      final wasUnread = _notifications.any((n) => n.id == id && !n.read);
      _notifications = [for (final n in _notifications) if (n.id != id) n];
      if (wasUnread && _unreadCount > 0) _unreadCount--;
      notifyListeners();
    } on ApiException {
      // swallow
    } catch (_) {
      // swallow
    }
  }

  Future<void> _pollUnreadCount() async {
    try {
      final count = await _repository.fetchUnreadCount();
      _unreadCount = count;
      notifyListeners();
    } catch (_) {
      // polling failure is silent
    }
  }
}
