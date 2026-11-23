import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/bn_format.dart';
import '../../core/widgets/ui.dart';
import '../../data/auth/auth_controller.dart';
import '../../data/auth/auth_models.dart';
import '../../data/auth/auth_repository.dart';

/// The applicant's own application, straight from the server.
final myApplicationProvider = FutureProvider.autoDispose<ApplicationStatus>(
  (ref) => ref.watch(authRepositoryProvider).myApplication(),
);

/// Where the application stands: under review, more info needed (upload
/// again), rejected (with reason) or approved (open the app).
class SignupStatusScreen extends ConsumerWidget {
  const SignupStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(myApplicationProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(myApplicationProvider.future),
            child: app.when(
              skipLoadingOnRefresh: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: e is ApiException ? e.message : 'অবস্থা দেখা যায়নি। আবার চেষ্টা করুন।',
                onRetry: () => ref.invalidate(myApplicationProvider),
              ),
              data: (a) => _StatusView(app: a),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusView extends ConsumerWidget {
  const _StatusView({required this.app});

  final ApplicationStatus app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, bg, fg, title, note) = switch (app.status) {
      'approved' => (Icons.verified_rounded, AppColors.softGreen, AppColors.primary, 'আবেদন অনুমোদিত হয়েছে', 'এখন আপনার বিনিয়োগের হিসাব দেখতে পারবেন'),
      'rejected' => (Icons.cancel_outlined, AppColors.dangerSoft, AppColors.danger, 'আবেদন বাতিল হয়েছে', 'কারণ নিচে দেখুন'),
      'more_info' => (Icons.info_outline_rounded, AppColors.amberSoft, AppColors.amber, 'আরও তথ্য লাগবে', 'নিচের তথ্যগুলো দিয়ে আবার জমা দিন'),
      'under_review' => (Icons.manage_search_rounded, AppColors.softGreen, AppColors.primary, 'যাচাই চলছে', 'সাধারণত ১ কার্যদিবস লাগে'),
      _ => (Icons.check_rounded, AppColors.softGreen, AppColors.primary, 'আবেদন জমা হয়েছে', 'যাচাই শুরু হলে এখানে দেখতে পাবেন'),
    };
    final missing = app.missingDocuments;
    final canUpload = app.status == 'submitted' || app.status == 'more_info';
    final otherRequested = app.requestedFields.where((f) => !DocKind.all.contains(f)).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
      children: [
        Center(
          child: Container(
            width: 76.r,
            height: 76.r,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: fg, size: 40.r),
          ),
        ),
        SizedBox(height: 14.h),
        Text(title, textAlign: TextAlign.center, style: AppText.headline),
        SizedBox(height: 4.h),
        Text(note, textAlign: TextAlign.center, style: AppText.caption.copyWith(fontSize: 15.sp)),
        SizedBox(height: 22.h),

        if (app.status == 'rejected')
          InfoBox(tone: InfoTone.bad, icon: Icons.error_outline_rounded, text: app.rejectionReason ?? 'কারণ জানতে অফিসে যোগাযোগ করুন।'),
        if (app.status == 'more_info' && (app.adminMessage ?? '').isNotEmpty) ...[
          InfoBox(tone: InfoTone.warn, icon: Icons.chat_bubble_outline_rounded, text: app.adminMessage!),
          SizedBox(height: 12.h),
        ],
        if (otherRequested.isNotEmpty) ...[
          InfoBox(
            tone: InfoTone.warn,
            icon: Icons.call_outlined,
            text: '${otherRequested.map(DocKind.label).join(', ')} বদলানো এখনো অ্যাপ থেকে যায় না — হেল্পলাইনে ফোন করে জানান।',
          ),
          SizedBox(height: 12.h),
        ],
        if (canUpload && missing.isNotEmpty) ...[
          _UploadCard(missing: missing),
          SizedBox(height: 12.h),
        ],
        if (app.status == 'more_info') ...[
          _ResubmitButton(blocked: missing.isNotEmpty),
          SizedBox(height: 12.h),
        ],

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('আবেদনের ইতিহাস', style: AppText.bodyStrong),
              SizedBox(height: 10.h),
              for (final (i, t) in app.timeline.reversed.indexed)
                _TimelineRow(entry: t, latest: i == 0, last: i == app.timeline.length - 1),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        AppCard(
          onTap: () => showDemoNotice(context, 'হেল্পলাইন নম্বর এখনো বসানো হয়নি: ${AppConfig.helpline}'),
          child: Row(
            children: [
              const IconBox(icon: Icons.call_outlined),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('কোনো প্রশ্ন আছে?', style: AppText.bodyStrong),
                    Text('হেল্পলাইন ${AppConfig.helpline} · সকাল ১০টা–সন্ধ্যা ৬টা', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        if (app.status == 'approved')
          const _OpenAppButton()
        else
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(myApplicationProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('অবস্থা আবার দেখুন'),
          ),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          child: const Text('লগআউট'),
        ),
      ],
    );
  }
}

/// Approved: re-read the user so the router opens the investor app.
class _OpenAppButton extends ConsumerStatefulWidget {
  const _OpenAppButton();

  @override
  ConsumerState<_OpenAppButton> createState() => _OpenAppButtonState();
}

class _OpenAppButtonState extends ConsumerState<_OpenAppButton> {
  bool _busy = false;

  Future<void> _open() async {
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).refreshUser();
    } on ApiException catch (e) {
      if (mounted) showDemoNotice(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      FilledButton(onPressed: _busy ? null : _open, child: Text(_busy ? 'খোলা হচ্ছে…' : 'আমার বিনিয়োগ দেখুন'));
}

class _ResubmitButton extends ConsumerStatefulWidget {
  const _ResubmitButton({required this.blocked});

  final bool blocked;

  @override
  ConsumerState<_ResubmitButton> createState() => _ResubmitButtonState();
}

class _ResubmitButtonState extends ConsumerState<_ResubmitButton> {
  bool _busy = false;

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).resubmit();
      if (mounted) showDemoNotice(context, 'আবার জমা হয়েছে। যাচাই হলে এখানে দেখবেন।');
      ref.invalidate(myApplicationProvider);
    } on ApiException catch (e) {
      if (mounted) showDemoNotice(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: widget.blocked || _busy ? null : _send,
        child: Text(_busy ? 'জমা হচ্ছে…' : widget.blocked ? 'আগে চাওয়া ছবিগুলো দিন' : 'আবার জমা দিন'),
      );
}

/// Photos the server still needs (failed upload or asked again by the office).
class _UploadCard extends ConsumerStatefulWidget {
  const _UploadCard({required this.missing});

  final List<String> missing;

  @override
  ConsumerState<_UploadCard> createState() => _UploadCardState();
}

class _UploadCardState extends ConsumerState<_UploadCard> {
  final _picker = ImagePicker();
  String? _uploading;

  Future<void> _take(String kind) async {
    Uint8List? bytes;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: kind == DocKind.selfie ? CameraDevice.front : CameraDevice.rear,
        maxWidth: 1600,
        imageQuality: 75,
      );
      bytes = file == null ? null : await file.readAsBytes();
    } catch (_) {
      if (mounted) showDemoNotice(context, 'ক্যামেরা খোলা যায়নি। অনুমতি দিয়ে আবার চেষ্টা করুন।');
      return;
    }
    if (bytes == null || !mounted) return;
    setState(() => _uploading = kind);
    try {
      await ref.read(authRepositoryProvider).uploadDocument(kind, bytes);
      if (mounted) showDemoNotice(context, '${DocKind.label(kind)} জমা হয়েছে।');
      ref.invalidate(myApplicationProvider);
    } on ApiException catch (e) {
      if (mounted) showDemoNotice(context, e.message);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('এই ছবিগুলো এখনো জমা হয়নি', style: AppText.bodyStrong),
          SizedBox(height: 4.h),
          Text('সব ছবি না পেলে যাচাই শেষ করা যায় না।', style: AppText.caption),
          SizedBox(height: 10.h),
          for (final kind in widget.missing)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: OutlinedButton.icon(
                onPressed: _uploading != null ? null : () => _take(kind),
                icon: _uploading == kind
                    ? SizedBox.square(dimension: 18.r, child: const CircularProgressIndicator(strokeWidth: 2))
                    : Icon(kind == DocKind.selfie ? Icons.face_outlined : Icons.photo_camera_outlined),
                label: Text(_uploading == kind ? 'পাঠানো হচ্ছে…' : '${DocKind.label(kind)} তুলুন'),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.latest, required this.last});

  final TimelineEntry entry;
  final bool latest;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: EdgeInsets.only(top: 3.h),
                decoration: BoxDecoration(
                  color: latest ? AppColors.primary : const Color(0xFFA9D6BB),
                  shape: BoxShape.circle,
                ),
              ),
              if (!last) Expanded(child: Container(width: 2, color: const Color(0xFFDDE3E0))),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title, style: AppText.bodyStrong),
                  Text(BnFormat.dateTime(entry.at), style: AppText.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24.w, 120.h, 24.w, 24.h),
      children: [
        Icon(Icons.cloud_off_rounded, size: 48.r, color: AppColors.textSecondary),
        SizedBox(height: 12.h),
        Text(message, textAlign: TextAlign.center, style: AppText.body),
        SizedBox(height: 16.h),
        FilledButton(onPressed: onRetry, child: const Text('আবার চেষ্টা করুন')),
      ],
    );
  }
}
