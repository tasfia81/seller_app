import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import 'app_button.dart';
import 'dialogs.dart';
import 'status_chip.dart';

/// Picks a photo from camera or gallery. Files stay in the app's private
/// cache (image_picker does not save to the public gallery). Never log paths.
class ImageCapture {
  static final _picker = ImagePicker();

  /// Returns the picked file, or null if cancelled. Shows a message on
  /// permission problems or a too-small (likely unreadable) image.
  static Future<XFile?> pick(BuildContext context, ImageSource source, {bool front = false}) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
        preferredCameraDevice: front ? CameraDevice.front : CameraDevice.rear,
      );
      if (file == null) return null;
      if (await file.length() < 15 * 1024) {
        if (context.mounted) {
          showAppSnack(context, 'ছবিটি খুব ছোট বা অস্পষ্ট। আবার পরিষ্কার ছবি দিন।', error: true);
        }
        return null;
      }
      return file;
    } on PlatformException {
      if (context.mounted) {
        showAppSnack(context, 'ক্যামেরা বা গ্যালারির অনুমতি দিন, তারপর আবার চেষ্টা করুন।', error: true);
      }
      return null;
    }
  }
}

class ImageUploadCard extends StatelessWidget {
  const ImageUploadCard({
    super.key,
    required this.title,
    required this.file,
    required this.onPicked,
    required this.onRemove,
    this.icon = Icons.photo_camera_outlined,
    this.circular = false,
    this.frontCamera = false,
    this.errorText,
    this.uploadProgress,
  });

  final String title;
  final XFile? file;
  final ValueChanged<XFile> onPicked;
  final VoidCallback onRemove;
  final IconData icon;
  final bool circular;
  final bool frontCamera;
  final String? errorText;

  /// 0..1 while uploading to the server (backend phase). Null = not uploading.
  final double? uploadProgress;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final f = await ImageCapture.pick(context, source, front: frontCamera);
    if (f != null) onPicked(f);
  }

  @override
  Widget build(BuildContext context) {
    final has = file != null;
    final hasError = errorText != null;
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: hasError ? AppColors.error : (has ? AppColors.border : const Color(0xFFB9C7BE)),
          width: hasError || !has ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(icon, color: AppColors.primary),
          SizedBox(width: 8.w),
          Expanded(child: Text(title, style: AppText.bodyStrong)),
          if (uploadProgress != null)
            StatusChip('আপলোড ${(uploadProgress! * 100).round()}%', tone: ChipTone.warning)
          else
            StatusChip(has ? 'যুক্ত হয়েছে' : 'বাকি', tone: has ? ChipTone.success : ChipTone.neutral),
        ]),
        SizedBox(height: 10.h),
        if (uploadProgress != null) ...[
          LinearProgressIndicator(value: uploadProgress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
          SizedBox(height: 10.h),
        ],
        if (has)
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(circular ? 40 : 8),
              child: kIsWeb
                  // On web the picked file path is a blob URL.
                  ? Image.network(
                      file!.path,
                      width: circular ? 72.r : 104.r,
                      height: circular ? 72.r : 66.r,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    )
                  : Image.file(
                      File(file!.path),
                      width: circular ? 72.r : 104.r,
                      height: circular ? 72.r : 66.r,
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      excludeFromSemantics: true,
                    ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: AppButton(
                label: 'বদলান',
                compact: true,
                variant: AppButtonVariant.outline,
                onPressed: () => _chooseSource(context),
              ),
            ),
            SizedBox(width: 8.w),
            IconButton(
              tooltip: 'ছবি সরান',
              onPressed: onRemove,
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                side: const BorderSide(color: Color(0xFFF1CFCF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorText),
            ),
          ])
        else
          Row(children: [
            Expanded(
              child: AppButton(
                label: 'ক্যামেরা',
                icon: Icons.photo_camera_outlined,
                compact: true,
                variant: AppButtonVariant.outline,
                onPressed: () => _pick(context, ImageSource.camera),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: AppButton(
                label: 'গ্যালারি',
                icon: Icons.photo_library_outlined,
                compact: true,
                variant: AppButtonVariant.outline,
                onPressed: () => _pick(context, ImageSource.gallery),
              ),
            ),
          ]),
        if (hasError) ...[
          SizedBox(height: 6.h),
          Text(errorText!, style: TextStyle(fontSize: 13.sp, color: const Color(0xFFC23B3B))),
        ],
      ]),
    );
  }

  Future<void> _chooseSource(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('ক্যামেরা দিয়ে তুলুন'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('গ্যালারি থেকে বাছুন'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          SizedBox(height: 8.h),
        ]),
      ),
    );
    if (source != null && context.mounted) await _pick(context, source);
  }
}
