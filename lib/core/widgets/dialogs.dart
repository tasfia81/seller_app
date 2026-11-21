import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'নিশ্চিত করুন',
  String cancelLabel = 'বাতিল',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          style: TextButton.styleFrom(minimumSize: const Size(64, 48), foregroundColor: AppColors.textSecondary),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            minimumSize: const Size(64, 48),
            foregroundColor: destructive ? AppColors.errorText : AppColors.primaryDark,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.errorText : AppColors.darkGreen,
    ));
}

/// Searchable single-choice bottom sheet (division, district, product…).
Future<T?> showSearchSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) labelOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _SearchSheet<T>(title: title, items: items, labelOf: labelOf),
  );
}

class _SearchSheet<T> extends StatefulWidget {
  const _SearchSheet({required this.title, required this.items, required this.labelOf});

  final String title;
  final List<T> items;
  final String Function(T) labelOf;

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = widget.items.where((e) => widget.labelOf(e).contains(_q.trim())).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: AppText.section.copyWith(fontSize: 17.sp)),
              SizedBox(height: 12.h),
              TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(
                  hintText: 'খুঁজুন',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('কিছু পাওয়া যায়নি', style: AppText.caption))
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(indent: 16, endIndent: 16),
                    itemBuilder: (_, i) => ListTile(
                      minTileHeight: 52,
                      title: Text(widget.labelOf(list[i]), style: AppText.input),
                      onTap: () => Navigator.of(context).pop(list[i]),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}
