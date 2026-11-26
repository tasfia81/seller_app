import '../../core/widgets/api_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
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
    final state = ref.watch(investorProfileProvider);
    if (!state.hasValue) return ApiStatus(state, onRetry: () => ref.invalidate(investorProfileProvider));
    final profile = state.valueOrNull!;
    final name = profile['name'] as String;
    final payout = profile['payout'] as Map;
    final nominee = profile['nominee'] as Map;
    final address = profile['address'] as Map;
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
                        child: Text(name.length < 2 ? name : name.substring(0, 2),
                            style: AppText.section.copyWith(color: AppColors.primaryDark)),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppText.title.copyWith(color: Colors.white)),
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
              ('মোবাইল', BnFormat.digits('${profile['mobile']}')),
              ('NID', BnFormat.digits('${profile['nid_masked']}')),
              ('ঠিকানা', [address['detail'], address['upazila'], address['district']].whereType<String>().join(', ')),
            ]),
            _Section(title: 'লাভ পাওয়ার মাধ্যম', rows: [
              ('নিবন্ধিত মাধ্যম', [payout['method_label'], payout['account_masked']].whereType<String>().join(' ')),
            ]),
            _Section(title: 'নমিনি', rows: [
              ('নাম', '${nominee['name'] ?? '—'}'),
              ('সম্পর্ক', '${nominee['relation'] ?? '—'}'),
              ('মোবাইল', BnFormat.digits('${nominee['mobile'] ?? '—'}')),
            ]),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: OutlinedButton(
                onPressed: () => context.push(AppRoutes.supportNew('account', 'অ্যাকাউন্ট ও যাচাই')),
                child: const Text('তথ্য বদলাতে অনুরোধ করুন'),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
              child: Text('তথ্য পরিবর্তনের জন্য অফিস সাপোর্টে যোগাযোগ করুন।',
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
