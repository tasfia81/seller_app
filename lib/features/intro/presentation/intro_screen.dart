import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import 'widgets/intro_art.dart';

class _Slide {
  const _Slide(this.art, this.title, this.body, this.cta, this.ctaIcon);
  final Widget art;
  final String title;
  final String body;
  final String cta;
  final IconData ctaIcon;
}

const _slides = [
  _Slide(IntroArtOne(), 'পড়াশোনার পাশাপাশি\nনিজের আয়',
      'ক্লাসের ফাঁকে, নিজের সুবিধামতো সময়ে কাজ করুন। প্রতিদিন কত আয় হলো, দেখুন অ্যাপেই।',
      'শুরু করুন', Icons.north_east_rounded),
  _Slide(IntroArtTwo(), 'অভিজ্ঞতা ছাড়াই\nশুরু করুন',
      'পণ্য আমরা দেব, নিজের টাকা লাগবে না। ফোনে ২–৩ ট্যাপেই বিক্রি লেখা যায়, শিখতে লাগে কয়েক মিনিট।',
      'পরবর্তী', Icons.arrow_forward_rounded),
  _Slide(IntroArtThree(), 'যত বিক্রি,\nতত বেশি আয়',
      'প্রতিটি বিক্রির কমিশন সাথে সাথে দেখুন। কত পেলেন আর কত বাকি — কোনো লুকানো হিসাব নেই।',
      'শুরু করি', Icons.arrow_forward_rounded),
];

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  void _finish() => context.go(AppRoutes.welcome);

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    right: 12.w,
                    child: TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0x38FFFFFF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 40),
                        shape: const StadiumBorder(),
                        textStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('এড়িয়ে যান'),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 4.h, 24.w, 16.h),
                child: Column(children: [
                  _Dots(count: _slides.length, index: _page),
                  SizedBox(height: 16.h),
                  AppButton(label: slide.cta, trailingIcon: slide.ctaIcon, onPressed: _next),
                  if (_page == 0) ...[
                    SizedBox(height: 12.h),
                    const _TrustRow(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 11, child: IntroHero(child: slide.art)),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 0),
            child: Column(children: [
              Text(slide.title, textAlign: TextAlign.center, style: AppText.headline),
              SizedBox(height: 8.h),
              Text(slide.body,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: AppColors.textSecondary, height: 1.65)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'স্লাইড ${index + 1} / $count',
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? AppColors.primary : const Color(0xFFD3DCD6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ]),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    Widget item(IconData i, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(t, style: AppText.small),
        ]);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14.w,
      runSpacing: 6.h,
      children: [
        item(Icons.verified_user_outlined, 'নিরাপদ ও বিশ্বস্ত'),
        item(Icons.schedule_rounded, 'নিজের সময়ে কাজ'),
        item(Icons.trending_up_rounded, 'স্বচ্ছ আয়'),
      ],
    );
  }
}
