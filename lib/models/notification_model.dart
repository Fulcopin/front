import 'package:flutter/material.dart';

enum NotificationType {
  productArrival,
  paymentRequired,
  statusChange,
  newUser,
  system
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final String? userId;
  final String? productId;
  final String? shipmentId;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.userId,
    this.productId,
    this.shipmentId,
    this.isRead = false,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.productArrival:
        return Icons.inventory_2_outlined;
      case NotificationType.paymentRequired:
        return Icons.payment_outlined;
      case NotificationType.statusChange:
        return Icons.local_shipping_outlined;
      case NotificationType.newUser:
        return Icons.person_add_outlined;
      case NotificationType.system:
        return Icons.notifications_outlined;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.productArrival:
        return Colors.green;
      case NotificationType.paymentRequired:
        return Colors.orange;
      case NotificationType.statusChange:
        return Colors.blue;
      case NotificationType.newUser:
        return Colors.purple;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    String? userId,
    String? productId,
    String? shipmentId,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      shipmentId: shipmentId ?? this.shipmentId,
      isRead: isRead ?? this.isRead,
    );
  }
}

