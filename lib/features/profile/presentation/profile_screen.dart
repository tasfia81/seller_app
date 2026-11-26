import '../../../core/errors/failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/seller.dart';
import '../data/profile_repository.dart';
import 'account_screen.dart' show SellerAvatar;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _requestChange(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(profileRepositoryProvider);
    if (repository is! ApiProfileRepository) return;
    const labels = {'mobile': 'মোবাইল নম্বর', 'present_address': 'বর্তমান ঠিকানা', 'emergency_contact': 'জরুরি যোগাযোগের ব্যক্তির নাম'};
    var field = 'mobile';
    var value = '';
    final request = await showDialog<(String, String)>(
      context: context,
      builder: (dialog) => StatefulBuilder(builder: (_, setState) => AlertDialog(
        title: const Text('তথ্য পরিবর্তনের অনুরোধ'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButton<String>(value: field, items: [
            for (final item in labels.entries) DropdownMenuItem(value: item.key, child: Text(item.value)),
          ], onChanged: (selected) => setState(() => field = selected ?? field)),
          TextField(onChanged: (text) => setState(() => value = text.trim()),
            decoration: const InputDecoration(labelText: 'নতুন তথ্য')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('বন্ধ')),
          FilledButton(onPressed: value.length < 3 ? null : () => Navigator.pop(dialog, (field, value)),
            child: const Text('পাঠান')),
        ],
      )),
    );
    if (request == null || !context.mounted) return;
    try {
      await repository.requestChange(request.$1, request.$2);
      if (context.mounted) showAppSnack(context, 'অনুরোধ অফিসে পাঠানো হয়েছে।');
    } catch (error) {
      if (context.mounted) showAppSnack(context, failureMessage(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('আমার প্রোফাইল')),
      body: AsyncValueView<SellerProfile>(
        value: value,
        onRetry: () => ref.invalidate(profileProvider),
        data: (p) => ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            Center(child: SellerAvatar(profile: p, size: 88)),
            SizedBox(height: 8.h),
            Text(p.name, textAlign: TextAlign.center, style: AppText.pageTitle.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(height: 4.h),
            Center(
              child: StatusChip(
                '${p.isActive ? 'সক্রিয়' : 'নিষ্ক্রিয়'} · ${p.isVerified ? 'যাচাইকৃত' : 'যাচাই বাকি'}',
                tone: p.isActive && p.isVerified ? ChipTone.success : ChipTone.warning,
              ),
            ),
            SizedBox(height: 16.h),
            AppCard(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
              child: Column(children: [
                _Field('মোবাইল নম্বর', BnFormat.phone(p.mobile)),
                _Field('বর্তমান ঠিকানা', p.presentAddress),
                _Field('স্থায়ী ঠিকানা', p.permanentAddress),
                _Field('জরুরি যোগাযোগ', p.emergencyContact),
                _Field('জাতীয় পরিচয়পত্র', p.maskedNid, last: true),
              ]),
            ),
            SizedBox(height: 10.h),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('নিরাপত্তার জন্য পরিচয়পত্রের ছবি ও পুরো নম্বর এখানে দেখানো হয় না।', style: AppText.small),
              ),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AppButton(
            label: 'তথ্য পরিবর্তনের অনুরোধ',
            variant: AppButtonVariant.outline,
            onPressed: () => _requestChange(context, ref),
          ),
          SizedBox(height: 6.h),
          Text('অ্যাডমিন অনুমোদন দিলে পরিবর্তন কার্যকর হবে', style: AppText.small),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.small),
        SizedBox(height: 2.h),
        Text(value, style: AppText.label),
      ]),
    );
  }
}
