import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../data/support_repository.dart';

IconData supportTopicIcon(String topic) => switch (topic) {
      'stock' => Icons.inventory_2_outlined,
      'sales' => Icons.receipt_long_outlined,
      'cash' => Icons.payments_outlined,
      'account' => Icons.verified_user_outlined,
      _ => Icons.more_horiz_rounded,
    };

/// "সাপোর্ট": ask the office about stock, sales, cash or the account.
class SupportHomeScreen extends ConsumerWidget {
  const SupportHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(supportThreadsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('সাপোর্ট')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(supportThreadsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
          children: [
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(16.r)),
              child: Row(
                children: [
                  Container(
                    width: 48.r,
                    height: 48.r,
                    decoration: const BoxDecoration(color: Color(0x1FFFFFFF), shape: BoxShape.circle),
                    child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 26.r),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('কোনো সমস্যা? অফিসকে লিখুন', style: AppText.section.copyWith(color: Colors.white)),
                        SizedBox(height: 2.h),
                        Text('সকাল ১০টা–সন্ধ্যা ৬টার মধ্যে অ্যাপেই উত্তর পাবেন',
                            style: AppText.caption.copyWith(color: AppColors.onDarkMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Text('কী বিষয়ে জানতে চান?', style: AppText.section),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: [
                for (final t in sellerSupportTopics)
                  SizedBox(
                    width: (1.sw - 32.w - 10.w) / 2,
                    child: AppCard(
                      onTap: () => context.push(AppRoutes.supportNew(t.id, t.label)),
                      child: Row(
                        children: [
                          Container(
                            width: 38.r,
                            height: 38.r,
                            decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(10.r)),
                            child: Icon(supportTopicIcon(t.id), color: AppColors.primary, size: 20.r),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(child: Text(t.label, style: AppText.bodyStrong, maxLines: 2)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 22.h),
            Text('আমার কথোপকথন', style: AppText.section),
            SizedBox(height: 10.h),
            AsyncValueView<List<SupportThread>>(
              value: threads,
              onRetry: () => ref.invalidate(supportThreadsProvider),
              data: (list) => list.isEmpty
                  ? AppCard(child: Text('এখনো কোনো প্রশ্ন করেননি। উপরের যেকোনো বিষয় বেছে লিখুন।', style: AppText.body))
                  : Column(
                      children: [
                        for (final t in list) ...[
                          _ThreadCard(thread: t, onTap: () => context.push(AppRoutes.supportThread(t.id))),
                          SizedBox(height: 10.h),
                        ],
                      ],
                    ),
            ),
            SizedBox(height: 10.h),
            const InfoBanner(
              icon: Icons.call_outlined,
              text: 'খুব জরুরি হলে (যেমন টাকা বা মাল হারানো) সরাসরি অফিসে ফোন করুন।',
            ),
            SizedBox(height: 10.h),
            const InfoBanner(
              icon: Icons.lock_outline_rounded,
              tone: BannerTone.warning,
              text: 'অফিস কখনো চ্যাটে বা ফোনে আপনার পাসওয়ার্ড বা OTP চায় না।',
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({required this.thread, required this.onTap});

  final SupportThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = thread.last;
    final (label, tone) = thread.resolved
        ? ('সমাধান হয়েছে', ChipTone.neutral)
        : (last?.fromOffice ?? false)
            ? ('উত্তর এসেছে', ChipTone.success)
            : ('উত্তরের অপেক্ষায়', ChipTone.warning);
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21.r,
            backgroundColor: AppColors.successSoft,
            child: Icon(supportTopicIcon(thread.topic), color: AppColors.primary, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(thread.topicLabel, style: AppText.bodyStrong, overflow: TextOverflow.ellipsis)),
                    StatusChip(label, tone: tone),
                  ],
                ),
                SizedBox(height: 3.h),
                if (last != null)
                  Text(
                    '${last.fromOffice ? 'অফিস: ' : 'আপনি: '}${last.text}',
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(BnFormat.dateTime(thread.updatedAt), style: AppText.small),
              ],
            ),
          ),
          if (thread.unread > 0) ...[
            SizedBox(width: 8.w),
            Semantics(
              label: '${thread.unread}টি নতুন উত্তর',
              child: Container(
                margin: EdgeInsets.only(top: 10.h),
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                child: Text(BnFormat.digits('${thread.unread}'), style: AppText.small.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
