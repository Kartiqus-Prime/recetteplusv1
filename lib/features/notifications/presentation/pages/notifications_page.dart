import 'package:flutter/material.dart';
import '../../../../core/services/notifications_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/models/notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsService _notificationsService = NotificationsService();
  String? _selectedFilter;

  final Map<String, String> _filters = {
    'all': 'Toutes',
    'order': 'Commandes',
    'new_content': 'Nouveau contenu',
    'promotion': 'Promotions',
    'unread': 'Non lues',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'mark_all_read':
                  await _notificationsService.markAllAsRead();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Toutes les notifications marquées comme lues')),
                    );
                  }
                  break;
                case 'test_notification_db':
                  await _notificationsService.createTestNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            '🔔 Notification temps réel créée ! Elle devrait apparaître automatiquement.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  break;
                case 'test_local_notification':
                  await PushNotificationService.sendTestLocalNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔔 Notification système envoyée !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  break;
                case 'check_status':
                  final status =
                      await PushNotificationService.checkNotificationStatus();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Status des Notifications'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: status.entries.map((entry) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '${entry.key}: ${entry.value}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    );
                  }
                  break;
                case 'show_fcm_token':
                  final token = await PushNotificationService.getCurrentToken();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Token FCM'),
                        content:
                            SelectableText(token ?? 'Token non disponible'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('Tout marquer comme lu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_notification_db',
                child: Row(
                  children: [
                    Icon(Icons.flash_on, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('🔔 Test temps réel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_local_notification',
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.green),
                    SizedBox(width: 8),
                    Text('🔔 Test système'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'check_status',
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Vérifier status'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'show_fcm_token',
                child: Row(
                  children: [
                    Icon(Icons.key),
                    SizedBox(width: 8),
                    Text('Voir token FCM'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Boutons de test rapide
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _notificationsService.createTestNotification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '🔔 Notification temps réel créée ! Elle devrait apparaître automatiquement.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.flash_on),
                        label: const Text('Test Temps Réel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await PushNotificationService
                              .sendTestLocalNotification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('🔔 Notification système envoyée !'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Test Système'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 Test Temps Réel : Crée une notification en DB qui devrait apparaître automatiquement\n💡 Test Système : Affiche directement une notification système',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Filtres
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final entry = _filters.entries.elementAt(index);
                final isSelected = _selectedFilter == entry.key;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = selected ? entry.key : null;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Liste des notifications avec Stream
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: _notificationsService.notificationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Erreur: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                var notifications = snapshot.data ?? [];

                // Appliquer les filtres
                if (_selectedFilter != null && _selectedFilter != 'all') {
                  if (_selectedFilter == 'unread') {
                    notifications =
                        notifications.where((n) => !n.isRead).toList();
                  } else {
                    notifications = notifications
                        .where((n) => n.type == _selectedFilter)
                        .toList();
                  }
                }

                if (notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Aucune notification',
                            style: TextStyle(fontSize: 18)),
                        SizedBox(height: 8),
                        Text('Vous êtes à jour !',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await _notificationsService.deleteNotification(notification.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification supprimée')),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: notification.isRead
                ? Colors.grey[300]
                : Theme.of(context).primaryColor,
            child: Icon(
              _getNotificationIcon(notification.type),
              color: notification.isRead ? Colors.grey[600] : Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.content),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    notification.formattedTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notification.typeDisplayName,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () async {
            if (!notification.isRead) {
              await _notificationsService.markAsRead(notification.id);
            }

            // Navigation basée sur le type et l'action URL
            if (notification.actionUrl != null) {
              Navigator.pushNamed(context, notification.actionUrl!);
            } else {
              _handleNotificationTap(notification);
            }
          },
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'new_content':
        return Icons.fiber_new;
      case 'promotion':
        return Icons.local_offer;
      case 'low_stock':
        return Icons.warning;
      case 'comment_reply':
        return Icons.reply;
      case 'auth':
        return Icons.security;
      case 'rating':
        return Icons.star;
      case 'price_drop':
        return Icons.trending_down;
      case 'test':
        return Icons.bug_report;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    // Navigation simple basée sur le type
    switch (notification.type) {
      case 'order':
        Navigator.pushNamed(context, '/profile'); // Aller aux commandes
        break;
      case 'new_content':
      case 'recipe':
        Navigator.pushNamed(context, '/recipes');
        break;
      case 'promotion':
      case 'product':
        Navigator.pushNamed(context, '/products');
        break;
      case 'video':
        Navigator.pushNamed(context, '/shorts');
        break;
      default:
        Navigator.pushNamed(context, '/home');
    }
  }
}
