import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/utils/bn_format.dart';
import '../../core/widgets/ui.dart';
import '../../data/investor_repository.dart';

/// Profile, payout method and nominee — personal data is always masked.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(summaryProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.only(bottom: 24.h + MediaQuery.paddingOf(context).bottom),
          children: [
            GradientHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'পেছনে যান',
                    light: false,
                    size: 44,
                    onTap: () => context.pop(),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30.r,
                        backgroundColor: Colors.white,
                        child: Text(s.investorName.substring(0, 2),
                            style: AppText.section.copyWith(color: AppColors.primaryDark)),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.investorName, style: AppText.title.copyWith(color: Colors.white)),
                            Row(
                              children: [
                                Icon(Icons.verified_rounded, size: 16.r, color: AppColors.onPrimaryMuted),
                                SizedBox(width: 4.w),
                                Text('যাচাইকৃত বিনিয়োগকারী',
                                    style: AppText.caption.copyWith(color: AppColors.onPrimaryMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _Section(title: 'ব্যক্তিগত তথ্য', rows: [
              ('মোবাইল', BnFormat.digits('017•••••678')),
              ('NID', BnFormat.maskNid('1990269482117')),
              ('ঠিকানা', 'মোহাম্মদপুর, ঢাকা'),
            ]),
            const _Section(title: 'লাভ পাওয়ার মাধ্যম', rows: [
              ('প্রধান', 'বিকাশ ••৭৭০২'),
              ('মূলধন ফেরত', 'ব্যাংক ••৪৮২১'),
            ]),
            _Section(title: 'নমিনি', rows: [
              ('নাম', 'সাবরিনা আহমেদ'),
              ('সম্পর্ক', 'স্ত্রী'),
              ('মোবাইল', BnFormat.digits('018•••••111')),
            ]),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: OutlinedButton(
                onPressed: () => showDemoNotice(context, 'ডেমো মোড: তথ্য বদলের অনুরোধ সার্ভার যুক্ত হলে যাবে।'),
                child: const Text('তথ্য বদলাতে অনুরোধ করুন'),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
              child: Text('নিরাপত্তার জন্য তথ্য বদলাতে OTP ও অ্যাডমিনের অনুমোদন লাগে।',
                  textAlign: TextAlign.center, style: AppText.small),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppText.cardTitle),
            SizedBox(height: 6.h),
            for (final r in rows) KeyValueRow(r.$1, r.$2),
          ],
        ),
      ),
    );
  }
}
