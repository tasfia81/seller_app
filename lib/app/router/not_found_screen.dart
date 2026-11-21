import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/state_views.dart';
import 'app_routes.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyView(
        icon: Icons.explore_off_outlined,
        title: 'পেজটি পাওয়া যায়নি',
        message: 'হোমে ফিরে আবার চেষ্টা করুন।',
        actionLabel: 'হোমে ফিরে যান',
        onAction: () => context.go(AppRoutes.home),
      ),
    );
  }
}
