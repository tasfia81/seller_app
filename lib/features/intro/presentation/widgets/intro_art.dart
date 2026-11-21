import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Hero illustrations for the intro slides: tilted floating cards over a
/// soft green gradient. Drawn on a fixed 360×440 design canvas and scaled
/// with FittedBox, so every phone gets the exact same composition.
class IntroHero extends StatelessWidget {
  const IntroHero({super.key, required this.child, this.alt = false});

  final Widget child;
  final bool alt;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: alt
              ? const [Color(0xFF2A9C5C), Color(0xFF8CD3A6), Color(0xFFE4F4EA), Colors.white]
              : const [Color(0xFF178A4B), Color(0xFF4DB477), Color(0xFFBFE6CC), Colors.white],
          stops: const [0, 0.4, 0.72, 1],
        ),
      ),
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(width: 360, height: 440, child: Stack(clipBehavior: Clip.none, children: [child])),
        ),
      ),
    );
  }
}

class _Float extends StatelessWidget {
  const _Float({
    required this.left,
    required this.top,
    required this.angle,
    required this.child,
    this.width,
    this.height,
    this.dark = false,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
  });

  final double left;
  final double top;
  final double angle; // degrees
  final double? width;
  final double? height;
  final bool dark;
  final EdgeInsets padding;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: dark ? AppColors.darkGreen : Colors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [BoxShadow(color: Color(0x2E0B3D2E), blurRadius: 28, offset: Offset(0, 12))],
          ),
          child: child,
        ),
      ),
    );
  }
}

const _muted = TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3);
const _mutedDark = TextStyle(fontSize: 13, color: AppColors.onDarkMuted, height: 1.3);
TextStyle _amount(double s, [Color c = AppColors.textPrimary]) =>
    TextStyle(fontSize: s, fontWeight: FontWeight.w700, color: c, height: 1.2);

Widget _circleIcon(IconData icon, {Color bg = AppColors.mint, Color fg = AppColors.primary, double size = 46}) =>
    Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: fg, size: size * 0.5),
    );

Widget _row(IconData icon, String label, String badge, Color badgeBg, Color badgeFg) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF4F7F5), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(11)),
          child: Text(badge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: badgeFg)),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.north_east_rounded, size: 16, color: AppColors.darkGreen),
        ),
      ]),
    );

/// Slide 1 — earning alongside studies.
class IntroArtOne extends StatelessWidget {
  const IntroArtOne({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      _Float(
        left: 150,
        top: 58,
        width: 240,
        angle: -8,
        dark: true,
        child: Row(children: [
          _circleIcon(Icons.calendar_month_outlined, bg: const Color(0x1FFFFFFF), fg: Colors.white),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('এই সপ্তাহে আমার আয়', style: _mutedDark),
            Text('৳৩,৮৪০', style: _amount(22, Colors.white)),
          ]),
        ]),
      ),
      _Float(
        left: 34,
        top: 318,
        width: 210,
        angle: -6,
        child: Row(children: [
          _circleIcon(Icons.wb_sunny_outlined),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('আজ ৩ ঘণ্টায় আয়', style: _muted),
            Text('৳৬২০', style: _amount(20)),
          ]),
        ]),
      ),
      _Float(
        left: 30,
        top: 150,
        width: 300,
        angle: -4,
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          _row(Icons.receipt_long_outlined, 'আজকের বিক্রি', '১৮', AppColors.successSoft, AppColors.successText),
          const SizedBox(height: 8),
          _row(Icons.inventory_2_outlined, 'কম স্টকের সতর্কতা', '৩', AppColors.errorSoft, AppColors.errorText),
          const SizedBox(height: 8),
          _row(Icons.payments_outlined, 'ক্যাশ জমা বাকি', '১', AppColors.warningSoft, AppColors.warningText),
        ]),
      ),
    ]);
  }
}

/// Slide 2 — no experience needed, 3-tap sale.
class IntroArtTwo extends StatelessWidget {
  const IntroArtTwo({super.key});

  @override
  Widget build(BuildContext context) {
    Widget step(String n) => Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Text(n, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        );
    Widget pill(String t, bool on) => Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.successSoft : Colors.white,
            border: Border.all(color: on ? AppColors.primary : AppColors.inputBorder, width: on ? 1.5 : 1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(t,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                  color: on ? AppColors.successText : AppColors.textPrimary)),
        );
    return Stack(clipBehavior: Clip.none, children: [
      const _Float(
        left: 22,
        top: 38,
        angle: -8,
        radius: 99,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bolt_rounded, size: 18, color: AppColors.successText),
          SizedBox(width: 6),
          Text('মাত্র ৩ ট্যাপ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.successText)),
        ]),
      ),
      _Float(
        left: 40,
        top: 84,
        width: 286,
        angle: 3,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.checkroom_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('জার্সি — বাংলাদেশ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('৳৪৫০ / পিস · সাইজ L', style: _muted),
              ]),
            ),
            step('১'),
          ]),
          const SizedBox(height: 12),
          Container(
            height: 46,
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.inputBorder), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const SizedBox(width: 46, child: Icon(Icons.remove_rounded, size: 18, color: AppColors.primary)),
              Expanded(child: Center(child: Text('২ পিস', style: _amount(18)))),
              const SizedBox(width: 46, child: Icon(Icons.add_rounded, size: 18, color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            pill('ক্যাশ', true),
            const SizedBox(width: 6),
            pill('বিকাশ', false),
            const SizedBox(width: 6),
            pill('নগদ', false),
            const Spacer(),
            step('২'),
          ]),
          const SizedBox(height: 12),
          Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(12)),
            child: const Text('বিক্রি নিশ্চিত করুন · ৳৯০০',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
      _Float(
        left: 128,
        top: 330,
        width: 220,
        angle: -5,
        dark: true,
        child: Row(children: [
          _circleIcon(Icons.check_rounded, bg: AppColors.primary, fg: Colors.white, size: 44),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('বিক্রি নিশ্চিত',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('৳৯০০ · সকাল ১০:৪৮', style: TextStyle(color: AppColors.onDarkMuted, fontSize: 12)),
          ]),
        ]),
      ),
    ]);
  }
}

class _Ring extends CustomPainter {
  const _Ring(this.fraction);
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    canvas.drawCircle(c, r, Paint()..color = AppColors.mint);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = const Color(0xFFDCEBE2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5);
  }

  @override
  bool shouldRepaint(_Ring old) => old.fraction != fraction;
}

/// Slide 3 — more sales, more earnings.
class IntroArtThree extends StatelessWidget {
  const IntroArtThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      _Float(
        left: 196,
        top: 50,
        width: 190,
        height: 130,
        angle: 8,
        dark: true,
        radius: 26,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.trending_up_rounded, color: AppColors.onDarkMuted),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('অনুমোদিত আয়', style: _mutedDark),
              Text('৳১০,৬২০', style: _amount(18, Colors.white)),
            ]),
          ],
        ),
      ),
      _Float(
        left: 22,
        top: 118,
        width: 300,
        angle: -5,
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(
              painter: const _Ring(0.7),
              child: Center(child: Text('৫০%', style: _amount(14, AppColors.successText))),
            ),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('এই মাসের আয়', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text('৳১২,৪৮০', style: _amount(26)),
            const Text('লাভের ৫০% কমিশন',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.successText)),
          ]),
        ]),
      ),
      _Float(
        left: 56,
        top: 270,
        width: 280,
        angle: 4,
        child: Row(children: [
          _circleIcon(Icons.check_rounded, bg: AppColors.successSoft, size: 44),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ক্যাশ জমা যাচাই হয়েছে', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('৳৩,৮০০ · গতকাল', style: _muted),
          ]),
        ]),
      ),
      _Float(
        left: 20,
        top: 370,
        angle: -3,
        radius: 99,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text.rich(TextSpan(
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          children: [
            const TextSpan(text: 'বাকি পাওনা '),
            TextSpan(text: '৳২,৬২০', style: _amount(13, AppColors.successText)),
          ],
        )),
      ),
    ]);
  }
}

/// Welcome — tilted feature tiles with a floating earnings card.
class WelcomeArt extends StatelessWidget {
  const WelcomeArt({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(double l, double t, Color bg, Color fg, Color iconBg, IconData icon, String label) => Positioned(
          left: l,
          top: t,
          width: 168,
          height: 150,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(26)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleIcon(icon, bg: iconBg, fg: fg, size: 52),
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        );
    return Stack(clipBehavior: Clip.none, children: [
      Positioned(
        left: -40,
        top: -10,
        width: 440,
        height: 420,
        child: Transform.rotate(
          angle: -10 * math.pi / 180,
          child: Stack(children: [
            tile(0, 30, const Color(0x8CFFFFFF), AppColors.darkGreen, const Color(0xB3FFFFFF), Icons.bolt_rounded,
                'দ্রুত বিক্রি'),
            tile(188, 0, AppColors.primaryDark, Colors.white, const Color(0x24FFFFFF), Icons.inventory_2_outlined,
                'আমার স্টক'),
            tile(0, 200, AppColors.darkGreen, Colors.white, const Color(0x1FFFFFFF), Icons.payments_outlined,
                'ক্যাশ জমা'),
            tile(188, 170, const Color(0x99FFFFFF), AppColors.darkGreen, const Color(0xBFFFFFFF),
                Icons.event_note_outlined, 'দিনের হিসাব'),
          ]),
        ),
      ),
      _Float(
        left: 40,
        top: 168,
        width: 286,
        angle: -6,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CustomPaint(
              painter: const _Ring(0.25),
              child: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('এই মাসে আমার আয়', style: TextStyle(fontSize: 14, color: AppColors.textBody)),
            Text('৳৮,৪৫০', style: _amount(26)),
            const Text('১৮ দিন · নিজের সময়ে', style: _muted),
          ]),
        ]),
      ),
    ]);
  }
}
