import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/widgets/dialogs.dart';
import 'widgets/menu_group.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;

  void _soon(String what) => showAppSnack(context, '$what শীঘ্রই চালু হবে।');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস ও সাহায্য')),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          MenuGroup(title: 'সেটিংস', items: [
            MenuEntry(null, 'ভাষা',
                trailing: Text('বাংলা', style: AppText.caption), onTap: () => _soon('ইংরেজি ভাষা')),
            MenuEntry(null, 'নোটিফিকেশন চালু',
                trailing: Switch(value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
                onTap: () => setState(() => _notifications = !_notifications)),
            MenuEntry(null, 'পাসওয়ার্ড পরিবর্তন', onTap: () => context.push(AppRoutes.forgotPassword)),
            MenuEntry(null, 'লেখার আকার',
                trailing: Text('ফোনের সেটিং অনুযায়ী', style: AppText.caption), onTap: null),
          ]),
          SizedBox(height: 16.h),
          MenuGroup(title: 'সাহায্য', items: [
            MenuEntry(Icons.call_outlined, 'অফিসে কল করুন', onTap: () => _soon('অফিসের নম্বর')),
            MenuEntry(Icons.help_outline_rounded, 'সাধারণ প্রশ্ন', onTap: () => _showFaq(context)),
            MenuEntry(Icons.shield_outlined, 'গোপনীয়তা নীতি', onTap: () => _soon('সম্পূর্ণ গোপনীয়তা নীতি')),
            MenuEntry(Icons.description_outlined, 'শর্তাবলি', onTap: () => _soon('শর্তাবলি')),
          ]),
          SizedBox(height: 16.h),
          Text('অ্যাপ সংস্করণ ১.০.০', textAlign: TextAlign.center, style: AppText.small),
        ],
      ),
    );
  }

  void _showFaq(BuildContext context) {
    const faqs = [
      ('বিক্রি ভুল হলে কী করব?', 'বিক্রির ইতিহাস থেকে বিক্রিটি খুলে "সংশোধনের অনুরোধ" পাঠান। নিশ্চিত বিক্রি মোছা যায় না।'),
      ('ইন্টারনেট না থাকলে?', 'বিক্রি "পাঠানো বাকি" হিসেবে থাকবে, ইন্টারনেট ফিরলে পাঠানো হবে।'),
      ('আয় কখন পাব?', 'অ্যাডমিন অনুমোদনের পর পেমেন্ট দেওয়া হয়। "আমার আয়" পেজে বাকি পাওনা দেখুন।'),
      ('ক্যাশ কীভাবে জমা দেব?', '"ক্যাশ জমা" পেজ থেকে পরিমাণ ও মাধ্যম দিয়ে পাঠান। অ্যাডমিন যাচাই করলে সম্পন্ন দেখাবে।'),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        builder: (_, c) => ListView(
          controller: c,
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          children: [
            Text('সাধারণ প্রশ্ন', style: AppText.section.copyWith(fontSize: 17.sp)),
            SizedBox(height: 8.h),
            for (final f in faqs)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                title: Text(f.$1, style: AppText.bodyStrong),
                childrenPadding: EdgeInsets.only(bottom: 12.h),
                expandedAlignment: Alignment.centerLeft,
                children: [Text(f.$2, style: AppText.body)],
              ),
          ],
        ),
      ),
    );
  }
}
