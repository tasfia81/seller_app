import '../../../core/api/api_client.dart';
import '../../../core/api/seller_payload.dart';
import '../../../core/constants/app_config.dart';
import '../../../shared/models/enums.dart';
import '../../auth/data/seller_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../shared/models/seller.dart';

abstract interface class NotificationRepository {
  Future<List<AppNotification>> getAll();
  Future<void> markRead([String? id]);
}

class PreviewNotificationRepository implements NotificationRepository {
  @override
  Future<void> markRead([String? id]) async {}

  @override
  Future<List<AppNotification>> getAll() async {
    DemoData.ensureEnabled();
    return DemoData.notifications;
  }
}

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => AppConfig.previewAuth
        ? PreviewNotificationRepository()
        : ApiNotificationRepository(ref.watch(sellerSessionProvider).api));

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this.api);
  final ApiClient api;

  @override
  Future<List<AppNotification>> getAll() async => [
    for (final row in jsonRows(await api.get('/seller/notifications')))
      AppNotification(
        id: row['id'] as String, title: row['title'] as String, body: row['body'] as String,
        time: date(row, 'at'), isRead: row['read'] == true,
        type: switch (row['kind']) {
          'stock_assigned' => NotificationType.stockAssigned,
          'price_changed' => NotificationType.priceChanged,
          'commission_updated' => NotificationType.commissionUpdated,
          'cash_verified' || 'payout' => NotificationType.cashVerified,
          'day_closed' => NotificationType.dayClosed,
          'return_approved' || 'return_rejected' || 'return_received' => NotificationType.returnUpdate,
          _ => NotificationType.announcement,
        },
      ),
  ];

  @override
  Future<void> markRead([String? id]) async {
    final path = id == null ? '/seller/notifications/read' : '/seller/notifications/${Uri.encodeComponent(id)}/read';
    await api.post(path);
  }
}

/// Holds the list so read/unread can change locally.
class NotificationsController extends AutoDisposeAsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() => ref.watch(notificationRepositoryProvider).getAll();

  Future<void> markRead([String? id]) async {
    final repository = ref.read(notificationRepositoryProvider);
    final list = state.valueOrNull;
    if (list == null) return;
    state = await AsyncValue.guard(() async {
      await repository.markRead(id);
      return [for (final n in list) if (id == null || n.id == id) n.markRead() else n];
    });
  }

  Future<void> markAllRead() => markRead();
}

final notificationsProvider =
    AsyncNotifierProvider.autoDispose<NotificationsController, List<AppNotification>>(NotificationsController.new);
