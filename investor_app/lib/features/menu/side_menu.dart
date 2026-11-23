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
import '../../data/auth/auth_controller.dart';
import '../../data/investor_repository.dart';
import '../common/sheets.dart';

/// Green menu that sits behind the shrinking screen.
class SideMenu extends ConsumerWidget {
  const SideMenu({super.key, required this.animation, required this.onClose});

  final Animation<double> animation;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider);
    final size = MediaQuery.sizeOf(context);
    final firstName = summary.investorName.split(' ').first;

    void then(VoidCallback action) {
      onClose();
      action();
    }

    final items = <_MenuItem>[
      _MenuItem(Icons.add_rounded, 'আরও বিনিয়োগ', () => then(() => showInvestSheet(context))),
      _MenuItem(Icons.payments_outlined, 'টাকা তুলুন', () => then(() => context.push(AppRoutes.withdraw))),
      _MenuItem(Icons.bar_chart_rounded, 'মাসিক রিপোর্ট', () => then(() => context.go(AppRoutes.report))),
      _MenuItem(Icons.description_outlined, 'আমার চুক্তিপত্র', () => then(() => showAgreementSheet(context))),
      _MenuItem(Icons.person_outline_rounded, 'প্রোফাইল ও নমিনি', () => then(() => context.push(AppRoutes.profile))),
      _MenuItem(Icons.support_agent_rounded, 'সাপোর্ট চ্যাট ও সাহায্য', () => then(() => context.push(AppRoutes.support))),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Stack(
          children: [
            // Faded "second card" peeking behind the shrunken screen.
            Positioned(
              left: size.width * 0.58,
              top: size.height * 0.2,
              bottom: size.height * 0.2,
              width: size.width * 0.6,
              child: FadeTransition(
                opacity: animation,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: const Color(0x1FFFFFFF)),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 12.h, 20.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26.r,
                          backgroundColor: Colors.white,
                          child: Text(summary.investorName.substring(0, 2),
                              style: AppText.cardTitle.copyWith(color: AppColors.primaryDark)),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(BnFormat.greeting(DateTime.now()),
                                  style: AppText.caption.copyWith(color: AppColors.onPrimaryMuted)),
                              Text(firstName, style: AppText.title.copyWith(color: Colors.white)),
                            ],
                          ),
                        ),
                        CircleIconButton(
                          icon: Icons.close_rounded,
                          label: 'মেনু বন্ধ করুন',
                          light: false,
                          onTap: onClose,
                        ),
                      ],
                    ),
                    SizedBox(height: 36.h),
                    SizedBox(
                      width: size.width * 0.56,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < items.length; i++)
                            _MenuTile(item: items[i], highlighted: i == 0),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: size.width * 0.56,
                      child: _MenuTile(
                        item: _MenuItem(Icons.logout_rounded, 'লগআউট', () => _confirmLogout(context, ref, onClose)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _confirmLogout(BuildContext context, WidgetRef ref, VoidCallback onClose) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লগআউট করবেন?'),
        content: const Text('আবার ঢুকতে মোবাইল নম্বর ও পাসওয়ার্ড লাগবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('লগআউট')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      onClose();
      // Clears the saved session; the router then shows the welcome screen.
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, this.highlighted = false});

  final _MenuItem item;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Material(
        color: highlighted ? AppColors.onPrimaryGlass : Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: item.onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                children: [
                  Icon(item.icon, color: Colors.white, size: 21.r),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppText.body.copyWith(
                        color: Colors.white,
                        fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
