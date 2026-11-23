import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/bn_format.dart';
import '../../core/widgets/ui.dart';
import '../../data/support/support_repository.dart';

IconData supportTopicIcon(String topic) => switch (topic) {
      'profit' => Icons.payments_outlined,
      'investment' => Icons.account_balance_wallet_outlined,
      'stock' => Icons.inventory_2_outlined,
      'account' => Icons.verified_user_outlined,
      'sales' => Icons.receipt_long_outlined,
      'cash' => Icons.savings_outlined,
      _ => Icons.more_horiz_rounded,
    };

/// "সাহায্য ও সাপোর্ট": pick a topic to ask the office, or reopen a past conversation.
class SupportHomeScreen extends ConsumerWidget {
  const SupportHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(supportTopicsProvider);
    final threads = ref.watch(supportThreadsProvider);

    Future<void> refresh() async {
      ref.invalidate(supportTopicsProvider);
      await ref.refresh(supportThreadsProvider.future);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 20.w, 26.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleIconButton(
                              icon: Icons.arrow_back_rounded,
                              label: 'পেছনে যান',
                              size: 44,
                              onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
                            ),
                            SizedBox(width: 12.w),
                            Text('সাহায্য ও সাপোর্ট', style: AppText.title.copyWith(color: Colors.white)),
                          ],
                        ),
                        SizedBox(height: 18.h),
                        Text('কোনো প্রশ্ন বা সন্দেহ?\nআমাদের লিখুন',
                            style: AppText.headline.copyWith(color: Colors.white, height: 1.3)),
                        SizedBox(height: 6.h),
                        Text('অফিসের টিম অ্যাপেই উত্তর দেবে · সকাল ১০টা–সন্ধ্যা ৬টা',
                            style: AppText.bodySmall.copyWith(color: AppColors.onPrimaryMuted)),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 28.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('কী বিষয়ে জানতে চান?', style: AppText.section),
                    SizedBox(height: 10.h),
                    topics.when(
                      loading: () => const _GridPlaceholder(),
                      error: (e, _) => _InlineError(error: e, onRetry: () => ref.invalidate(supportTopicsProvider)),
                      data: (list) => GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10.h,
                        crossAxisSpacing: 10.w,
                        childAspectRatio: 1.55,
                        children: [
                          for (final t in list)
                            _TopicTile(
                              icon: supportTopicIcon(t.id),
                              label: t.label,
                              onTap: () => context.push(AppRoutes.supportNew(t.id, t.label)),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Text('আমার কথোপকথন', style: AppText.section),
                    SizedBox(height: 10.h),
                    threads.when(
                      skipLoadingOnRefresh: true,
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => _InlineError(error: e, onRetry: () => ref.invalidate(supportThreadsProvider)),
                      data: (list) => list.isEmpty
                          ? AppCard(
                              child: Text('এখনো কোনো প্রশ্ন করেননি। উপরের যেকোনো বিষয় বেছে লিখুন।', style: AppText.bodySmall),
                            )
                          : Column(
                              children: [
                                for (final t in list) ...[
                                  _ThreadTile(thread: t, onTap: () => context.push(AppRoutes.supportThread(t.id))),
                                  SizedBox(height: 10.h),
                                ],
                              ],
                            ),
                    ),
                    SizedBox(height: 12.h),
                    AppCard(
                      onTap: () => showDemoNotice(context, 'হেল্পলাইন নম্বর এখনো বসানো হয়নি: ${AppConfig.helpline}'),
                      child: Row(
                        children: [
                          const IconBox(icon: Icons.call_outlined, background: AppColors.amberSoft, color: AppColors.amber),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('জরুরি হলে ফোন করুন', style: AppText.bodyStrong),
                                Text('হেল্পলাইন ${AppConfig.helpline}', style: AppText.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    const InfoBox(
                      tone: InfoTone.plain,
                      icon: Icons.lock_outline_rounded,
                      text: 'আমরা কখনো OTP, পাসওয়ার্ড বা অন্য অ্যাকাউন্টে টাকা পাঠাতে বলি না — চ্যাটেও না।',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconBox(icon: icon, size: 38),
              Text(label, style: AppText.bodyStrong.copyWith(fontSize: 14.sp, height: 1.3), maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.onTap});

  final SupportThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = thread;
    final (bg, fg, label) = t.resolved
        ? (const Color(0xFFECEFED), const Color(0xFF45524A), 'সমাধান হয়েছে')
        : t.lastFromOffice
            ? (AppColors.softGreen, AppColors.primaryDark, 'উত্তর এসেছে')
            : (AppColors.amberSoft, AppColors.amber, 'উত্তরের অপেক্ষায়');
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(icon: supportTopicIcon(t.topic), circle: true),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(t.topicLabel, style: AppText.bodyStrong, overflow: TextOverflow.ellipsis)),
                    SizedBox(width: 8.w),
                    Pill(label, background: bg, color: fg),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  '${t.lastFromOffice ? 'অফিস: ' : 'আপনি: '}${t.lastMessage}',
                  style: AppText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(BnFormat.dateTime(t.updatedAt), style: AppText.small),
              ],
            ),
          ),
          if (t.unread > 0) ...[
            SizedBox(width: 8.w),
            Semantics(
              label: '${t.unread}টি নতুন উত্তর',
              child: Container(
                margin: EdgeInsets.only(top: 10.h),
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                child: Text(BnFormat.digits('${t.unread}'),
                    style: AppText.small.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GridPlaceholder extends StatelessWidget {
  const _GridPlaceholder();

  @override
  Widget build(BuildContext context) => SizedBox(height: 200.h, child: const Center(child: CircularProgressIndicator()));
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.textSecondary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(error is ApiException ? (error as ApiException).message : 'লোড করা যায়নি।', style: AppText.bodySmall),
          ),
          TextButton(onPressed: onRetry, child: const Text('আবার')),
        ],
      ),
    );
  }
}
