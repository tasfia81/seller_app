import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/constants/app_config.dart';
import 'brand_mark.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: Stack(
            children: [
              // Decorative rings — painted once, never repainted.
              Positioned(
                right: -size.width * 0.42,
                top: size.height * 0.08,
                child: RepaintBoundary(
                  child: CustomPaint(size: Size.square(size.width * 1.05), painter: _RingsPainter()),
                ),
              ),
              SafeArea(
                // Fills the screen on normal phones, scrolls on very small ones.
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const BrandMark(size: 42),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('স্ট্রিট সেলস', style: AppText.cardTitle.copyWith(color: Colors.white)),
                              Text('বিনিয়োগ',
                                  style: AppText.small.copyWith(color: AppColors.onPrimaryMuted, letterSpacing: 2)),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(flex: 2),
                      Container(width: 40, height: 2, color: Colors.white),
                      SizedBox(height: 14.h),
                      Text('আপনার টাকা কোথায়, কী করছে — সব দেখুন',
                          style: AppText.display.copyWith(color: Colors.white, fontSize: 32.sp)),
                      SizedBox(height: 12.h),
                      Text(
                        'আপনার বিনিয়োগে আমরা কাপড় কিনি, যাচাই করা সেলাররা বিক্রি করে। প্রতিটি পিস, প্রতিটি টাকা — আপনার চোখের সামনে।',
                        style: AppText.body.copyWith(color: const Color(0xFFD3E7DE)),
                      ),
                      SizedBox(height: 24.h),
                      const _TrustRow(),
                      const Spacer(flex: 3),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
                        onPressed: () => context.push(AppRoutes.signupMobile),
                        child: const Text('বিনিয়োগকারী হিসেবে যুক্ত হোন'),
                      ),
                      SizedBox(height: 12.h),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0x59FFFFFF)),
                        ),
                        // UI phase: login goes straight to the dashboard (demo data).
                        onPressed: () => context.go(AppRoutes.home),
                        child: const Text('আমার অ্যাকাউন্ট আছে — লগইন'),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'ট্রেড লাইসেন্স ${AppConfig.tradeLicense} · বিনিয়োগে ঝুঁকি আছে, লাভ বিক্রির উপর নির্ভর করে',
                        textAlign: TextAlign.center,
                        style: AppText.small.copyWith(color: const Color(0xFFC2DBD0)),
                      ),
                    ],
                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.description_outlined, 'লিখিত চুক্তি'),
      (Icons.schedule_rounded, 'লাইভ ট্র্যাকিং'),
      (Icons.receipt_long_outlined, 'প্রতি টাকার রসিদ'),
    ];
    const line = BorderSide(color: Color(0x2EFFFFFF));
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(top: line, bottom: line)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const VerticalDivider(color: Color(0x2EFFFFFF), width: 1, thickness: 1),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: i == 0 ? 0 : 10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(items[i].$1, color: Colors.white, size: 20.r),
                      SizedBox(height: 6.h),
                      Text(items[i].$2, style: AppText.caption.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x2EFFFFFF);
    for (final f in [1.0, 0.77, 0.54]) {
      canvas.drawCircle(c, r * f, faint);
    }
    canvas.drawCircle(c, r * 0.31, faint..color = const Color(0x59FFFFFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
