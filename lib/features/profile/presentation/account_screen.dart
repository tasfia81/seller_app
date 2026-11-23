import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/utils/bn_format.dart';
import '../../../shared/models/seller.dart';
import '../../auth/data/auth_repository.dart';
import '../../cash_handover/data/cash_repository.dart';
import '../data/profile_repository.dart';
import 'widgets/menu_group.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(context,
        title: 'লগআউট করবেন?', message: 'আবার লগইন করতে মোবাইল নম্বর ও পাসওয়ার্ড লাগবে।', confirmLabel: 'লগআউট', destructive: true);
    if (!ok) return;
    await ref.read(authRepositoryProvider).logout();
    if (context.mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final cashLeft = ref.watch(cashSummaryProvider).valueOrNull?.remaining ?? 0;
    return Scaffold(
      appBar: AppBar(titleSpacing: 16.w, title: const Text('অ্যাকাউন্ট')),
      body: AsyncValueView<SellerProfile>(
        value: profile,
        onRetry: () => ref.invalidate(profileProvider),
        data: (p) => ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            AppCard(
              onTap: () => context.push(AppRoutes.profile),
              child: Row(children: [
                SellerAvatar(profile: p, size: 56),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: AppText.section.copyWith(fontSize: 16.sp)),
                    Text(BnFormat.phone(p.mobile), style: AppText.caption),
                    SizedBox(height: 4.h),
                    StatusChip(p.isActive ? 'সক্রিয় সেলার' : 'নিষ্ক্রিয়', tone: p.isActive ? ChipTone.success : ChipTone.error),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A968F)),
              ]),
            ),
            SizedBox(height: 16.h),
            MenuGroup(title: 'আমার কাজ', items: [
              MenuEntry(Icons.trending_up_rounded, 'আমার আয়', onTap: () => context.push(AppRoutes.earnings)),
              MenuEntry(Icons.inventory_2_outlined, 'আমার স্টক', onTap: () => context.push(AppRoutes.inventory)),
              MenuEntry(Icons.payments_outlined, 'ক্যাশ জমা',
                  trailing: cashLeft > 0 ? StatusChip('${BnFormat.money(cashLeft)} বাকি', tone: ChipTone.warning) : null,
                  onTap: () => context.push(AppRoutes.cashHandover)),
              MenuEntry(Icons.event_note_outlined, 'দিনের হিসাব', onTap: () => context.push(AppRoutes.dayClosing)),
            ]),
            SizedBox(height: 16.h),
            MenuGroup(title: 'অ্যাকাউন্ট', items: [
              MenuEntry(Icons.person_outline_rounded, 'ব্যক্তিগত তথ্য', onTap: () => context.push(AppRoutes.profile)),
              MenuEntry(Icons.verified_user_outlined, 'যাচাইয়ের অবস্থা',
                  trailing: StatusChip(p.isVerified ? 'যাচাইকৃত' : 'যাচাই বাকি',
                      tone: p.isVerified ? ChipTone.success : ChipTone.warning),
                  onTap: () => context.push(AppRoutes.applicationStatus)),
              MenuEntry(Icons.support_agent_rounded, 'সাপোর্ট চ্যাট — অফিসকে লিখুন', onTap: () => context.push(AppRoutes.support)),
              MenuEntry(Icons.settings_outlined, 'সেটিংস ও সাহায্য', onTap: () => context.push(AppRoutes.settings)),
              MenuEntry(Icons.logout_rounded, 'লগআউট', danger: true, onTap: () => _logout(context, ref)),
            ]),
          ],
        ),
      ),
    );
  }
}

class SellerAvatar extends StatelessWidget {
  const SellerAvatar({super.key, required this.profile, this.size = 56});
  final SellerProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size.r / 2,
      backgroundColor: const Color(0xFFDCEBE2),
      foregroundImage: profile.photoUrl == null ? null : NetworkImage(profile.photoUrl!),
      child: Text(profile.initials,
          style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700, fontSize: (size * 0.36).sp)),
    );
  }
}
