import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/inputs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/seller.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'সব';

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(notificationsProvider);
    final ctrl = ref.read(notificationsProvider.notifier);
    final hasUnread = value.valueOrNull?.any((n) => !n.isRead) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('নোটিফিকেশন'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: ctrl.markAllRead,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text('সব পড়া হয়েছে'),
            ),
          SizedBox(width: 4.w),
        ],
      ),
      body: AsyncValueView<List<AppNotification>>(
        value: value,
        onRetry: () => ref.invalidate(notificationsProvider),
        data: (all) {
          final filters = ['সব', ...{for (final t in NotificationType.values) t.filterLabel}];
          final list = _filter == 'সব' ? all : all.where((n) => n.type.filterLabel == _filter).toList();
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final todays = list.where((n) => !n.time.isBefore(today)).toList();
          final older = list.where((n) => n.time.isBefore(today)).toList();
          return Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
              child: ChoicePills<String>(
                options: filters,
                selected: _filter,
                labelOf: (f) => f,
                style: PillStyle.filter,
                scrollable: true,
                onSelected: (f) => setState(() => _filter = f),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyView(
                      icon: Icons.notifications_none_rounded,
                      title: 'কোনো নোটিফিকেশন নেই',
                      message: 'নতুন স্টক, দাম বা পেমেন্টের খবর এখানে আসবে।',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(notificationsProvider.future),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                        children: [
                          if (todays.isNotEmpty) _group('আজ', todays, ctrl),
                          if (older.isNotEmpty) _group('আগের', older, ctrl),
                        ],
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _group(String title, List<AppNotification> items, NotificationsController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: EdgeInsets.fromLTRB(4.w, 8.h, 0, 8.h),
        child: Text(title, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
      ),
      for (final n in items)
        Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: _NotificationTile(n: n, onTap: () => ctrl.markRead(n.id)),
        ),
    ]);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n, required this.onTap});
  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (n.type) {
      NotificationType.stockAssigned => (Icons.inventory_2_outlined, AppColors.successSoft, AppColors.primary),
      NotificationType.priceChanged => (Icons.sell_outlined, AppColors.warningSoft, AppColors.warningText),
      NotificationType.commissionUpdated => (Icons.trending_up_rounded, AppColors.successSoft, AppColors.primary),
      NotificationType.cashVerified => (Icons.payments_outlined, AppColors.successSoft, AppColors.primary),
      NotificationType.returnUpdate => (Icons.assignment_return_outlined, AppColors.neutralSoft, AppColors.neutralText),
      NotificationType.dayClosed => (Icons.event_available_outlined, AppColors.neutralSoft, AppColors.neutralText),
      NotificationType.announcement => (Icons.campaign_outlined, AppColors.neutralSoft, AppColors.neutralText),
    };
    return Semantics(
      label: n.isRead ? null : 'নতুন',
      child: Material(
        color: n.isRead ? Colors.white : const Color(0xFFF1F8F4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(color: n.isRead ? AppColors.border : const Color(0xFFCFE6D8)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: fg, size: 22),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.title, style: AppText.bodyStrong),
                  SizedBox(height: 2.h),
                  Text(n.body, style: AppText.caption.copyWith(color: AppColors.textBody)),
                  SizedBox(height: 2.h),
                  Text(BnFormat.time(n.time), style: AppText.small),
                ]),
              ),
              if (!n.isRead)
                Container(
                  margin: EdgeInsets.only(top: 6.h, left: 6.w),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
