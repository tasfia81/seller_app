import '../../core/widgets/api_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/widgets/ui.dart';
import '../../data/investor_repository.dart';
import '../../data/models.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _saving = false;

  Future<void> _markRead() async {
    setState(() => _saving = true);
    try {
      await ref.read(investorRepositoryProvider).markNoticesRead();
      if (!mounted) return;
      ref.invalidate(noticesProvider);
      ref.invalidate(summaryProvider);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(noticesProvider);
    if (!itemsState.hasValue) return ApiStatus(itemsState, onRetry: () => ref.invalidate(noticesProvider));
    final items = itemsState.valueOrNull!;
    final unread = items.where((notice) => !notice.read).length;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 8.h),
                child: Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'পেছনে যান',
                      size: 44,
                      iconColor: AppColors.primary,
                      onTap: () => context.pop(),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(child: Text('নোটিফিকেশন', style: AppText.title)),
                    TextButton(
                      onPressed: unread == 0 || _saving ? null : _markRead,
                      child: const Text('সব পড়া হয়েছে'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h + MediaQuery.paddingOf(context).bottom),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, i) => _NoticeCard(notice: items[i], unread: i < unread),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.unread});

  final InvestorNotice notice;
  final bool unread;

  static IconData _icon(NoticeIcon i) => switch (i) {
        NoticeIcon.money => Icons.attach_money_rounded,
        NoticeIcon.stock => Icons.inventory_2_outlined,
        NoticeIcon.seller => Icons.person_add_alt_outlined,
        NoticeIcon.alert => Icons.warning_amber_rounded,
        NoticeIcon.report => Icons.description_outlined,
        NoticeIcon.withdraw => Icons.north_rounded,
        NoticeIcon.contract => Icons.verified_user_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (notice.tone) {
      NoticeTone.good => (AppColors.softGreen, AppColors.primary),
      NoticeTone.warn => (AppColors.amberSoft, AppColors.amber),
      NoticeTone.bad => (AppColors.dangerSoft, AppColors.danger),
    };
    return AppCard(
      radius: 18,
      padding: EdgeInsets.all(14.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(icon: _icon(notice.icon), background: bg, color: fg),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(notice.title, style: AppText.bodyStrong)),
                    SizedBox(width: 8.w),
                    Text(notice.time, style: AppText.small),
                    if (unread) ...[
                      SizedBox(width: 6.w),
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.dot, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Text(notice.body, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
