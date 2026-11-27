import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';

/// Green gradient header with rounded bottom corners (reference style).
class GradientHeader extends StatelessWidget {
  const GradientHeader(
      {super.key, required this.child, this.padding, this.rounded = true});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final radius =
        rounded ? BorderRadius.vertical(bottom: Radius.circular(28.r)) : null;
    return DecoratedBox(
      decoration: BoxDecoration(
          gradient: AppColors.headerGradient, borderRadius: radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const RadialGradient(
            center: Alignment(0.75, -0.85),
            radius: 1.25,
            colors: [Color(0x309CE8C6), Color(0x009CE8C6)],
          ),
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.fromLTRB(16.w, top + 10.h, 16.w, 20.h),
          child: child,
        ),
      ),
    );
  }
}

/// Round icon button. [light] = white circle with dark icon; otherwise a
/// translucent circle with a white icon (for use on the green header).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.light = true,
    this.badge = false,
    this.size,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool light;
  final bool badge;
  final double? size;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 48.r.clamp(44.0, 56.0).toDouble();
    final fg = iconColor ?? (light ? AppColors.textPrimary : Colors.white);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: light ? Colors.white : AppColors.onPrimaryGlass,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: s,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: s * 0.44, color: fg),
                if (badge)
                  Positioned(
                    top: s * 0.22,
                    right: s * 0.24,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.dot,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White rounded card. Tappable when [onTap] is set (ripple is clipped).
class AppCard extends StatelessWidget {
  const AppCard(
      {super.key,
      required this.child,
      this.padding,
      this.onTap,
      this.color = Colors.white,
      this.radius});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color color;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? 20.r);
    final content =
        Padding(padding: padding ?? EdgeInsets.all(16.r), child: child);
    final isLight = color == Colors.white;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: r),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: isLight
              ? AppColors.glassGradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.alphaBlend(const Color(0x18FFFFFF), color), color],
                ),
          borderRadius: r,
          border: Border.all(
              color: isLight ? AppColors.glassEdge : const Color(0x35FFFFFF)),
        ),
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// Small square/round icon holder.
class IconBox extends StatelessWidget {
  const IconBox({
    super.key,
    required this.icon,
    this.background = AppColors.softGreen,
    this.color = AppColors.primary,
    this.size = 42,
    this.circle = false,
  });

  final IconData icon;
  final Color background;
  final Color color;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final s = size.r;
    return Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(12.r),
      ),
      child: Icon(icon, size: s * 0.46, color: color),
    );
  }
}

/// Small rounded label (status, counts).
class Pill extends StatelessWidget {
  const Pill(this.text,
      {super.key,
      this.background = AppColors.softGreen,
      this.color = AppColors.primary});

  final String text;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 2.h),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(9.r)),
      child: Text(text,
          style: AppText.small
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

/// Section title with an optional text action on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppText.section)),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

/// Label / value row used in breakdowns.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value,
      {super.key, this.strong = false, this.valueColor});

  final String label;
  final String value;
  final bool strong;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label,
                style: strong
                    ? AppText.bodyStrong
                    : AppText.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
          ),
          SizedBox(width: 12.w),
          Text(value,
              textAlign: TextAlign.right,
              style: (strong
                      ? AppText.bodyStrong.copyWith(fontWeight: FontWeight.w700)
                      : AppText.label)
                  .copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

/// iOS-style segmented control (grey track, white selected pill).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs(
      {super.key,
      required this.labels,
      required this.index,
      required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
          color: const Color(0xFFE6EBE8),
          borderRadius: BorderRadius.circular(14.r)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    height: 44.h.clamp(44.0, 52.0).toDouble(),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: i == index
                          ? const [
                              BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1))
                            ]
                          : null,
                    ),
                    child: Text(
                      labels[i],
                      style: AppText.label.copyWith(
                        fontWeight:
                            i == index ? FontWeight.w700 : FontWeight.w500,
                        color: i == index
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Row of pill-shaped filter chips (dark when selected).
class FilterPills extends StatelessWidget {
  const FilterPills(
      {super.key,
      required this.labels,
      required this.index,
      required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (var i = 0; i < labels.length; i++)
          Semantics(
            button: true,
            selected: i == index,
            child: Material(
              color: i == index ? AppColors.dark : Colors.white,
              shape: StadiumBorder(
                side: BorderSide(
                    color:
                        i == index ? AppColors.dark : AppColors.borderStrong),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onChanged(i),
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        labels[i],
                        style: AppText.label.copyWith(
                          color:
                              i == index ? Colors.white : AppColors.textPrimary,
                          fontWeight:
                              i == index ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Label above an input, as in the design. Pass [controller] / [onChanged] for
/// real forms; [errorText] shows the problem in red under the field.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.initialValue,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.helper,
    this.helperOk = false,
    this.prefix,
    this.suffix,
    this.controller,
    this.onChanged,
    this.errorText,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction,
    this.autofillHints,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String? initialValue;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? helper;
  final bool helperOk;
  final Widget? prefix;
  final Widget? suffix;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: AppText.label),
          SizedBox(height: 6.h)
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          keyboardType: keyboardType,
          obscureText: obscure,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction ?? TextInputAction.next,
          autofillHints: autofillHints,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          style: AppText.body.copyWith(height: 1.3),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
            counterText: '',
            errorText: errorText,
            errorMaxLines: 3,
          ),
        ),
        if (helper != null && errorText == null) ...[
          SizedBox(height: 4.h),
          Text(helper!,
              style: AppText.small.copyWith(
                  color:
                      helperOk ? AppColors.primary : AppColors.textSecondary)),
        ],
      ],
    );
  }
}

/// Label above a dropdown. Controlled when [onChanged] is given ([value] may be
/// null until the user picks); otherwise it keeps its own selection.
class LabeledDropdown extends StatefulWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.options,
    this.semanticLabel,
    this.value,
    this.onChanged,
    this.hint,
    this.errorText,
  });

  final String label;
  final List<String> options;
  final String? semanticLabel;
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final String? errorText;

  @override
  State<LabeledDropdown> createState() => _LabeledDropdownState();
}

class _LabeledDropdownState extends State<LabeledDropdown> {
  late String? _value = widget.onChanged == null ? widget.options.first : null;

  @override
  Widget build(BuildContext context) {
    final controlled = widget.onChanged != null;
    final current = controlled ? widget.value : _value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label, style: AppText.label),
          SizedBox(height: 6.h)
        ],
        DropdownButtonFormField<String>(
          // Rebuild when the option list changes (e.g. districts of a new division).
          key: ValueKey('${widget.options.join('|')}#$current'),
          value: widget.options.contains(current) ? current : null,
          isExpanded: true,
          style: AppText.body.copyWith(height: 1.3),
          borderRadius: BorderRadius.circular(12.r),
          dropdownColor: Colors.white,
          hint: widget.hint == null
              ? null
              : Text(widget.hint!,
                  style: AppText.body.copyWith(color: AppColors.textSecondary)),
          decoration: InputDecoration(
              hintText: widget.semanticLabel, errorText: widget.errorText),
          items: [
            for (final o in widget.options)
              DropdownMenuItem(value: o, child: Text(o))
          ],
          onChanged: (v) {
            if (v == null) return;
            if (controlled) {
              widget.onChanged!(v);
            } else {
              setState(() => _value = v);
            }
          },
        ),
      ],
    );
  }
}

/// Tinted info box (green / amber / red).
class InfoBox extends StatelessWidget {
  const InfoBox(
      {super.key, required this.text, this.icon, this.tone = InfoTone.good});

  final String text;
  final IconData? icon;
  final InfoTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      InfoTone.good => (AppColors.softGreen, AppColors.primaryDark),
      InfoTone.warn => (AppColors.amberSoft, AppColors.amber),
      InfoTone.bad => (AppColors.dangerSoft, AppColors.dangerText),
      InfoTone.plain => (Colors.transparent, AppColors.textSecondary),
    };
    return Container(
      padding: tone == InfoTone.plain ? EdgeInsets.zero : EdgeInsets.all(12.r),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14.r)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Icon(icon, size: 18.r, color: fg)),
            SizedBox(width: 10.w),
          ],
          Expanded(
              child: Text(text, style: AppText.caption.copyWith(color: fg))),
        ],
      ),
    );
  }
}

enum InfoTone { good, warn, bad, plain }

/// Short message at the bottom of the screen (errors, results, honest
/// "not available yet" notices).
void showDemoNotice(BuildContext context, [String? message]) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message ??
          'ডেমো মোড: সার্ভার এখনো যুক্ত হয়নি, তাই এটা এখনো কাজ করবে না।'),
    ));
}

/// Bottom sheet with a title and content.
Future<void> showInfoSheet(BuildContext context,
    {required String title, required List<Widget> children}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppText.title),
            SizedBox(height: 12.h),
            ...children,
          ],
        ),
      ),
    ),
  );
}
