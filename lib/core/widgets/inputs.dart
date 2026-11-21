import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_size.dart';
import '../../app/theme/app_text.dart';
import '../utils/bn_format.dart';

/// +/- quantity control. [step] and [decimals] come from the product's unit,
/// so pieces go 1,2,3 and kilograms go 0.5,1.0,1.5.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.step,
    required this.onChanged,
    this.min = 0,
    this.max,
  });

  final double value;
  final double step;
  final double min;
  final double? max;
  final ValueChanged<double> onChanged;

  double _round(double v) => (v * 1000).roundToDouble() / 1000;

  @override
  Widget build(BuildContext context) {
    final canDec = value - step >= min - 0.0001;
    final canInc = max == null || value + step <= max! + 0.0001;
    final h = 56.h.clamp(52.0, 64.0).toDouble();
    Widget btn(IconData icon, String tip, bool enabled, double delta) => SizedBox(
          width: h,
          height: h,
          child: IconButton(
            tooltip: tip,
            onPressed: enabled ? () => onChanged(_round(value + delta)) : null,
            icon: Icon(icon),
            color: AppColors.primary,
            disabledColor: AppColors.disabled,
          ),
        );
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(children: [
        btn(Icons.remove_rounded, 'কমান', canDec, -step),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border.symmetric(vertical: BorderSide(color: AppColors.border)),
            ),
            child: Text(BnFormat.qty(value), style: AppText.amount(22)),
          ),
        ),
        btn(Icons.add_rounded, 'বাড়ান', canInc, step),
      ]),
    );
  }
}

enum PillStyle { filter, select }

/// Horizontal set of pill choices. `filter` = dark selected (tabs/filters),
/// `select` = soft green selected (form choices).
class ChoicePills<T> extends StatelessWidget {
  const ChoicePills({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.style = PillStyle.select,
    this.scrollable = false,
    this.equalWidth = false,
    this.iconOf,
  });

  final List<T> options;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final PillStyle style;
  final bool scrollable;
  final bool equalWidth;
  final IconData? Function(T)? iconOf;

  @override
  Widget build(BuildContext context) {
    final pills = [for (final o in options) _pill(o)];
    if (equalWidth) {
      return Row(children: [
        for (var i = 0; i < pills.length; i++) ...[
          if (i > 0) SizedBox(width: 8.w),
          Expanded(child: pills[i]),
        ],
      ]);
    }
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var i = 0; i < pills.length; i++) ...[
            if (i > 0) SizedBox(width: 8.w),
            pills[i],
          ],
        ]),
      );
    }
    return Wrap(spacing: 8.w, runSpacing: 8.h, children: pills);
  }

  Widget _pill(T o) {
    final on = o == selected;
    final filter = style == PillStyle.filter;
    final bg = on ? (filter ? AppColors.darkGreen : AppColors.successSoft) : Colors.white;
    final fg = on ? (filter ? Colors.white : AppColors.successText) : AppColors.textPrimary;
    final border = on ? (filter ? AppColors.darkGreen : AppColors.primary) : AppColors.inputBorder;
    final icon = iconOf?.call(o);
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: bg,
        shape: StadiumBorder(side: BorderSide(color: border, width: on && !filter ? 1.5 : 1)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => onSelected(o),
          child: Container(
            constraints: BoxConstraints(minHeight: 40.h.clamp(40.0, 48.0).toDouble()),
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 16, color: fg), SizedBox(width: 6.w)],
              Flexible(
                child: Text(labelOf(o),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14.sp, color: fg, fontWeight: on ? FontWeight.w600 : FontWeight.w500)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.total, required this.current});

  final int total;
  final int current; // 1-based

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var i = 0; i < total; i++) ...[
        if (i > 0) SizedBox(width: 6.w),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            decoration: BoxDecoration(
              color: i < current ? AppColors.primary : AppColors.disabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    ]);
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({super.key, required this.hint, required this.onChanged, this.keyboardType});

  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.touch,
      child: TextField(
        onChanged: onChanged,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.search,
        style: AppText.input,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// Checkbox row with wrapped label, full-row tap target.
class CheckRow extends StatelessWidget {
  const CheckRow({super.key, required this.value, required this.onChanged, required this.child});

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
          ),
          SizedBox(width: 4.w),
          Expanded(child: Padding(padding: EdgeInsets.only(top: 9.h), child: child)),
        ]),
      ),
    );
  }
}
