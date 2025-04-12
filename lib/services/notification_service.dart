import 'dart:async';
import '../models/notification_model.dart';

class NotificationService {
  // Lista de notificaciones simuladas
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      title: 'Producto llegó a bodega',
      message: 'El producto "Smartphone XYZ" ha llegado a nuestra bodega. Se requiere pago.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.productArrival,
      userId: '2',
      productId: '1',
    ),
    NotificationModel(
      id: '2',
      title: 'Pago pendiente',
      message: 'El cliente "María González" tiene un pago pendiente para el envío VB-87654321.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      type: NotificationType.paymentRequired,
      userId: '2',
      shipmentId: '2',
    ),
    NotificationModel(
      id: '3',
      title: 'Cambio de estado de envío',
      message: 'El envío VB-12345678 ha pasado a estado "En tránsito".',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.statusChange,
      shipmentId: '1',
    ),
    NotificationModel(
      id: '4',
      title: 'Nuevo usuario registrado',
      message: 'El usuario "Carlos Rodríguez" se ha registrado en la plataforma.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.newUser,
      userId: '3',
    ),
    NotificationModel(
      id: '5',
      title: 'Mantenimiento programado',
      message: 'El sistema estará en mantenimiento el día 30/03/2025 de 2:00 AM a 4:00 AM.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      type: NotificationType.system,
    ),
  ];

  // Controlador para transmitir notificaciones en tiempo real
  final _notificationController = StreamController<NotificationModel>.broadcast();

  // Getter para el stream de notificaciones
  Stream<NotificationModel> get notificationStream => _notificationController.stream;

  // Método para obtener todas las notificaciones
  Future<List<NotificationModel>> getNotifications() async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    return List.from(_notifications);
  }

  // Método para obtener notificaciones no leídas
  Future<List<NotificationModel>> getUnreadNotifications() async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    return _notifications.where((notification) => !notification.isRead).toList();
  }

  // Método para marcar una notificación como leída
  Future<bool> markAsRead(String notificationId) async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return false;
    
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    return true;
  }

  // Método para crear una notificación de producto llegado a bodega
  Future<NotificationModel> createProductArrivalNotification({
    required String userId,
    required String productId,
    required String productName,
  }) async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Producto llegó a bodega',
      message: 'El producto "$productName" ha llegado a nuestra bodega. Se requiere pago.',
      timestamp: DateTime.now(),
      type: NotificationType.productArrival,
      userId: userId,
      productId: productId,
    );
    
    _notifications.insert(0, notification);
    _notificationController.add(notification);
    
    return notification;
  }

  // Método para crear una notificación de cambio de estado de envío
  Future<NotificationModel> createShipmentStatusNotification({
    required String shipmentId,
    required String trackingNumber,
    required String status,
  }) async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Cambio de estado de envío',
      message: 'El envío $trackingNumber ha pasado a estado "$status".',
      timestamp: DateTime.now(),
      type: NotificationType.statusChange,
      shipmentId: shipmentId,
    );
    
    _notifications.insert(0, notification);
    _notificationController.add(notification);
    
    return notification;
  }

  // Método para eliminar una notificación
  Future<bool> deleteNotification(String notificationId) async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return false;
    
    _notifications.removeAt(index);
    return true;
  }

  // Método para eliminar todas las notificaciones
  Future<bool> clearAllNotifications() async {
    // Simular retraso de red
    await Future.delayed(const Duration(seconds: 1));
    
    _notifications.clear();
    return true;
  }

  // Método para obtener el conteo de notificaciones no leídas
  Future<int> getUnreadCount() async {
    return _notifications.where((n) => !n.isRead).length;
  }

  // Cerrar el controlador cuando ya no se necesite
  void dispose() {
    _notificationController.close();
  }
}

