import 'package:flutter/material.dart';

class NotificationsProvider with ChangeNotifier {
  // Simple list to store notifications
  int _unreadCount = 0;

  // Getter for unread notifications count
  int get unreadCount => _unreadCount;

  // Add new notification (just increments the counter for now)
  void addNotification() {
    _unreadCount++;
    notifyListeners();
  }

  // Mark all as read
  void markAllAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }
}
