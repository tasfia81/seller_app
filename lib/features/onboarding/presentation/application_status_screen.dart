import '../../../core/constants/app_config.dart';
import '../../auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/image_upload_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/seller.dart';
import '../data/onboarding_repository_impl.dart';

class ApplicationStatusScreen extends ConsumerWidget {
  const ApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(applicationStatusProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('আবেদনের অবস্থা'),
        leading: IconButton(
          tooltip: 'বন্ধ করুন',
          icon: const Icon(Icons.close_rounded),
          onPressed: () async {
            await ref.read(authRepositoryProvider).logout();
            if (context.mounted) context.go(AppRoutes.welcome);
          },
        ),
      ),
      body: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(applicationStatusProvider),
        data: (info) => RefreshIndicator(
          onRefresh: () => ref.refresh(applicationStatusProvider.future),
          child: ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(info.id, style: AppText.caption)),
                    StatusChip.application(info.status),
                  ]),
                  SizedBox(height: 4.h),
                  Text('জমার তারিখ: ${BnFormat.dateFull(info.submittedAt)}', style: AppText.caption),
                  SizedBox(height: 12.h),
                  for (final s in info.timeline) _TimelineRow(step: s),
                ]),
              ),
              if (info.status == ApplicationStatus.moreInfoRequired && info.adminMessage != null) ...[
                SizedBox(height: 12.h),
                Text(info.adminMessage!),
                for (final field in info.requestedDocuments.where(_documentLabels.containsKey))
                  _ResubmitCard(key: ValueKey(field), field: field),
                if (!AppConfig.previewAuth)
                  AppButton(label: 'আবার জমা দিন', onPressed: () async {
                    final repository = ref.read(onboardingRepositoryProvider);
                    if (repository is! ApiOnboardingRepository) return;
                    try {
                      await repository.resubmit();
                      if (context.mounted) ref.invalidate(applicationStatusProvider);
                    } catch (error) {
                      if (context.mounted) showAppSnack(context, failureMessage(error), error: true);
                    }
                  }),
              ],
              if (info.status == ApplicationStatus.submitted) ...[
                for (final field in info.missingDocuments.where(_documentLabels.containsKey))
                  _ResubmitCard(key: ValueKey(field), field: field),
              ],
              if (info.status == ApplicationStatus.rejected) ...[
                SizedBox(height: 12.h),
                InfoBanner(
                  tone: BannerTone.error,
                  icon: Icons.cancel_outlined,
                  text: 'আবেদন বাতিল হয়েছে। কারণ: ${info.rejectionReason ?? 'জানানো হয়নি'}',
                ),
              ],
              if (info.status == ApplicationStatus.approved) ...[
                SizedBox(height: 16.h),
                AppButton(label: 'লগইন করুন', onPressed: () => context.go(AppRoutes.login)),
              ],
              SizedBox(height: 20.h),
              Text('সব অবস্থা', style: AppText.caption),
              SizedBox(height: 8.h),
              Wrap(spacing: 6.w, runSpacing: 6.h, children: [
                for (final s in ApplicationStatus.values) StatusChip.application(s),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step});
  final ApplicationTimelineStep step;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, border) = switch (step.state) {
      TimelineState.done => (AppColors.primary, Colors.white, Icons.check_rounded, AppColors.primary),
      TimelineState.current => (AppColors.successSoft, AppColors.primary, Icons.more_horiz_rounded, AppColors.primary),
      TimelineState.attention => (AppColors.warningSoft, AppColors.warningText, Icons.priority_high_rounded, AppColors.warning),
      TimelineState.upcoming => (AppColors.neutralSoft, AppColors.neutralSoft, Icons.circle, AppColors.neutralSoft),
    };
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: border, width: 1.5)),
          child: Icon(icon, size: 16, color: fg),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(step.title,
                style: AppText.bodyStrong.copyWith(
                    color: step.state == TimelineState.upcoming ? AppColors.textSecondary : AppColors.textPrimary)),
            if (step.time != null) Text(BnFormat.dateTime(step.time!), style: AppText.small),
            if (step.state == TimelineState.attention) Text('এখন', style: AppText.small),
          ]),
        ),
      ]),
    );
  }
}

const _documentLabels = {
  'nid_front': 'পরিচয়পত্রের সামনের ছবি',
  'nid_back': 'পরিচয়পত্রের পেছনের ছবি',
  'photo': 'নিজের ছবি',
};
class _ResubmitCard extends ConsumerStatefulWidget {
  const _ResubmitCard({super.key, required this.field});
  final String field;

  @override
  ConsumerState<_ResubmitCard> createState() => _ResubmitCardState();
}

class _ResubmitCardState extends ConsumerState<_ResubmitCard> {
  XFile? _file;
  bool _sending = false;
  bool _sent = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      if (repository is ApiOnboardingRepository) {
        await repository.uploadDocument(widget.field, _file!.path);
      }
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) showAppSnack(context, failureMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.warningSurface,
      borderColor: AppColors.warningBorder,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_sent)
          const InfoBanner(text: 'ছবিটি আপলোড হয়েছে।', icon: Icons.schedule_rounded)
        else ...[
          ImageUploadCard(
            title: _documentLabels[widget.field]!,
            icon: Icons.badge_outlined,
            file: _file,
            onPicked: (f) => setState(() => _file = f),
            onRemove: () => setState(() => _file = null),
          ),
          SizedBox(height: 10.h),
          AppButton(label: 'ছবিটি পাঠান', loading: _sending, onPressed: _file == null ? null : _send),
        ],
      ]),
    );
  }
}
