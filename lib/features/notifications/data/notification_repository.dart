import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../shared/models/seller.dart';

abstract interface class NotificationRepository {
  Future<List<AppNotification>> getAll();
}

class PreviewNotificationRepository implements NotificationRepository {
  @override
  Future<List<AppNotification>> getAll() async {
    DemoData.ensureEnabled();
    return DemoData.notifications;
  }
}

final notificationRepositoryProvider =
    Provider<NotificationRepository>((_) => PreviewNotificationRepository());

/// Holds the list so read/unread can change locally.
class NotificationsController extends AutoDisposeAsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() => ref.watch(notificationRepositoryProvider).getAll();

  void markRead(String id) {
    final list = state.valueOrNull;
    if (list == null) return;
    state = AsyncData([for (final n in list) n.id == id ? n.markRead() : n]);
  }

  void markAllRead() {
    final list = state.valueOrNull;
    if (list == null) return;
    state = AsyncData([for (final n in list) n.markRead()]);
  }
}

final notificationsProvider =
    AsyncNotifierProvider.autoDispose<NotificationsController, List<AppNotification>>(NotificationsController.new);
