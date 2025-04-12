import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/notification_model.dart';

class AdminNotificationsPanel extends StatelessWidget {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final Function(NotificationModel)? onMarkAsRead;
  final Function(NotificationModel)? onDelete;
  final Function()? onClearAll;
  final Function()? onViewAll;

  const AdminNotificationsPanel({
    Key? key,
    required this.notifications,
    this.isLoading = false,
    this.onMarkAsRead,
    this.onDelete,
    this.onClearAll,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notificaciones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onClearAll,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar Todo'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onViewAll,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Ver Todas'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (notifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No hay notificaciones',
                    style: TextStyle(
                      color: AppTheme.mutedTextColor,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length > 5 ? 5 : notifications.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: notification.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notification.icon,
                        color: notification.color,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.message),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!notification.isRead)
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () => onMarkAsRead?.call(notification),
                            tooltip: 'Marcar como leída',
                            iconSize: 20,
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => onDelete?.call(notification),
                          tooltip: 'Eliminar',
                          color: Colors.red,
                          iconSize: 20,
                        ),
                      ],
                    ),
                    onTap: () => onMarkAsRead?.call(notification),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Hace un momento';
    }
  }

  Widget _buildLoadingState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar Todo'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Ver Todas'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}

