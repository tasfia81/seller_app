import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/step_scaffold.dart';
import '../../core/widgets/ui.dart';
import 'signup_draft.dart';

class SignupKycScreen extends ConsumerStatefulWidget {
  const SignupKycScreen({super.key});

  @override
  ConsumerState<SignupKycScreen> createState() => _SignupKycScreenState();
}

class _SignupKycScreenState extends ConsumerState<SignupKycScreen> {
  final _picker = ImagePicker();
  late final SignupDraft _d = ref.read(signupDraftProvider);
  late final _nid = TextEditingController(text: _d.nid);
  late Uint8List? _front = _d.nidFront;
  late Uint8List? _back = _d.nidBack;
  late Uint8List? _selfie = _d.selfie;
  String? _nidError;
  bool _photoError = false;

  @override
  void dispose() {
    _nid.dispose();
    super.dispose();
  }

  void _next() {
    final nid = Validators.nid(_nid.text);
    final photosOk = _front != null && _back != null && _selfie != null;
    setState(() {
      _nidError = nid == null ? '১০, ১৩ বা ১৭ সংখ্যার NID নম্বর দিন' : null;
      _photoError = !photosOk;
    });
    if (nid == null || !photosOk) {
      showDemoNotice(context, nid == null ? 'NID নম্বর ঠিক করুন।' : 'NID-এর দুই পাশ ও সেলফি — তিনটি ছবিই লাগবে।');
      return;
    }
    _d
      ..nid = nid
      ..nidFront = _front
      ..nidBack = _back
      ..selfie = _selfie;
    context.push(AppRoutes.signupPayout);
  }

  /// Picks a compressed photo (keeps memory low and uploads fast later).
  Future<Uint8List?> _pick({bool selfie = false}) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: selfie ? CameraDevice.front : CameraDevice.rear,
        maxWidth: 1600,
        imageQuality: 75,
      );
      return file == null ? null : await file.readAsBytes();
    } catch (_) {
      if (mounted) showDemoNotice(context, 'ক্যামেরা খোলা যায়নি। অনুমতি দিয়ে আবার চেষ্টা করুন।');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 3,
      title: 'পরিচয় যাচাই',
      subtitle: 'আপনার টাকা যেন শুধু আপনার নামেই থাকে — তাই NID ও ছবি লাগে।',
      buttonLabel: 'পরের ধাপ',
      onNext: _next,
      children: [
        LabeledField(
          label: 'NID নম্বর',
          hint: '১০, ১৩ বা ১৭ সংখ্যা',
          controller: _nid,
          keyboardType: TextInputType.number,
          maxLength: 17,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9০-৯]'))],
          errorText: _nidError,
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: _PhotoSlot(
                label: 'সামনের দিক',
                bytes: _front,
                onTap: () async {
                  final b = await _pick();
                  if (b != null) setState(() => _front = b);
                },
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _PhotoSlot(
                label: 'পেছনের দিক',
                bytes: _back,
                onTap: () async {
                  final b = await _pick();
                  if (b != null) setState(() => _back = b);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        _SelfieSlot(
          bytes: _selfie,
          onTap: () async {
            final b = await _pick(selfie: true);
            if (b != null) setState(() => _selfie = b);
          },
        ),
        if (_photoError) ...[
          SizedBox(height: 8.h),
          const InfoBox(tone: InfoTone.bad, icon: Icons.error_outline_rounded, text: 'তিনটি ছবিই তুলুন — NID-এর সামনে, পেছনে ও সেলফি।'),
        ],
        SizedBox(height: 14.h),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ভালো ছবির জন্য', style: AppText.bodyStrong),
              SizedBox(height: 4.h),
              Text('• আলোতে তুলুন, ঝলক যেন না থাকে\n• কার্ডের চার কোণা ফ্রেমের ভেতরে রাখুন\n• সেলফিতে চশমা/মাস্ক খুলে নিন',
                  style: AppText.bodySmall.copyWith(color: const Color(0xFF3C4842))),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        const InfoBox(
          tone: InfoTone.plain,
          icon: Icons.lock_outline_rounded,
          text: 'ছবিগুলো গোপন সার্ভারে থাকে, শুধু যাচাইকারী দেখেন। কেউ দেখলে সেটা লগে লেখা থাকে।',
        ),
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.label, required this.bytes, required this.onTap});

  final String label;
  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = bytes != null;
    return Semantics(
      button: true,
      label: 'NID $label${done ? ', ছবি নেওয়া হয়েছে' : ''}',
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: done ? AppColors.primary : const Color(0xFF9AA59E), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 150.h,
            child: done
                ? Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(8.r),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            // cacheWidth keeps the decoded image small → no jank.
                            child: Image.memory(bytes!, fit: BoxFit.cover, width: double.infinity, cacheWidth: 400),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 8.h),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16.r, color: AppColors.primary),
                            SizedBox(width: 4.w),
                            Expanded(child: Text(label, style: AppText.small.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700))),
                            Text('বদলান', style: AppText.small.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_outlined, color: AppColors.primary, size: 28.r),
                      SizedBox(height: 6.h),
                      Text(label, style: AppText.label),
                      Text('ছবি তুলুন', style: AppText.small),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SelfieSlot extends StatelessWidget {
  const _SelfieSlot({required this.bytes, required this.onTap});

  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = bytes != null;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: done ? AppColors.primary : const Color(0xFF9AA59E), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox.square(
                  dimension: 52.r,
                  child: done
                      ? Image.memory(bytes!, fit: BoxFit.cover, cacheWidth: 160)
                      : const ColoredBox(
                          color: AppColors.softGreen,
                          child: Icon(Icons.face_outlined, color: AppColors.primary),
                        ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(done ? 'সেলফি নেওয়া হয়েছে' : 'সেলফি তুলুন', style: AppText.bodyStrong),
                    Text('NID-এর ছবির সাথে মেলানো হবে', style: AppText.caption),
                  ],
                ),
              ),
              Icon(done ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                  color: done ? AppColors.primary : AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
