import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// RFID Door Lock scenario configuration
class RfidScenario {
  final String command; // Incoming command from hardware
  final String message; // Message to display to user

  RfidScenario({required this.command, required this.message});

  Map<String, String> toMap() {
    return {'command': command, 'message': message};
  }

  factory RfidScenario.fromMap(Map<String, dynamic> map) {
    return RfidScenario(
      command: map['command'] as String? ?? '',
      message: map['message'] as String? ?? '',
    );
  }
}

/// Notification for RFID Door Lock
class DoorNotification {
  final String id;
  final String deviceId;
  final String message;
  final DateTime timestamp;

  DoorNotification({
    required this.id,
    required this.deviceId,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DoorNotification.fromMap(Map<String, dynamic> map) {
    return DoorNotification(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      message: map['message'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

/// Notification manager for RFID Door Locks
class NotificationManager extends ChangeNotifier {
  final List<DoorNotification> _notifications = [];
  static const String _prefKey = 'door_notifications';

  List<DoorNotification> get notifications => List.unmodifiable(_notifications);

  int get count => _notifications.length;

  void addNotification(DoorNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  void loadNotifications(List<DoorNotification> notifications) {
    _notifications.clear();
    _notifications.addAll(notifications);
    notifyListeners();
  }

  /// Save notifications to SharedPreferences
  Future<void> saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications
          .map((n) => jsonEncode(n.toMap()))
          .toList();
      await prefs.setStringList(_prefKey, jsonList);
    } catch (e) {
      print('[NotificationManager] Error saving notifications: $e');
    }
  }

  /// Load notifications from SharedPreferences
  Future<void> loadNotificationsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_prefKey) ?? [];
      final notifications = jsonList
          .map((json) => DoorNotification.fromMap(jsonDecode(json)))
          .toList();
      loadNotifications(notifications);
    } catch (e) {
      print('[NotificationManager] Error loading notifications: $e');
    }
  }
}

/// Auto Lock Door state
class AutoLockDoorState {
  final String state; // 'locked' or 'open'
  final int remainingSeconds; // countdown timer

  AutoLockDoorState({required this.state, this.remainingSeconds = 0});

  bool get isLocked => state == 'locked';
  bool get isOpen => state == 'open';
}
