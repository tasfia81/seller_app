import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';

/// Label shown above a field: "নাম *" or "ইমেইল (ঐচ্ছিক)".
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false, this.optional = false, this.trailing});

  final String text;
  final bool required;
  final bool optional;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(TextSpan(text: text, style: AppText.label, children: [
              if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
              if (optional)
                TextSpan(text: ' (ঐচ্ছিক)', style: AppText.small),
            ])),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.required = false,
    this.optional = false,
    this.hint,
    this.controller,
    this.initialValue,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.onChanged,
    this.prefixText,
    this.prefixIcon,
    this.suffix,
    this.helper,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.obscureText = false,
    this.autofillHints,
    this.maxLength,
  });

  final String? label;
  final bool required;
  final bool optional;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final String? prefixText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? helper;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) FieldLabel(label!, required: required, optional: optional),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          maxLines: obscureText ? 1 : maxLines,
          readOnly: readOnly,
          onTap: onTap,
          obscureText: obscureText,
          autofillHints: autofillHints,
          maxLength: maxLength,
          style: AppText.input,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          scrollPadding: EdgeInsets.only(bottom: 120.h),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20, color: AppColors.textSecondary),
            suffixIcon: suffix,
            helperText: helper,
            helperStyle: AppText.small,
            counterText: '',
          ),
        ),
      ],
    );
  }
}

/// Password / PIN field with show-hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.onChanged,
    this.required = false,
    this.textInputAction = TextInputAction.next,
    this.hint,
  });

  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool required;
  final TextInputAction textInputAction;
  final String? hint;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      required: widget.required,
      controller: widget.controller,
      validator: widget.validator,
      onChanged: widget.onChanged,
      hint: widget.hint,
      obscureText: _hidden,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: const [AutofillHints.password],
      suffix: IconButton(
        tooltip: _hidden ? 'পাসওয়ার্ড দেখুন' : 'পাসওয়ার্ড লুকান',
        icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: () => setState(() => _hidden = !_hidden),
      ),
    );
  }
}

/// A read-only field that opens a picker (date, list, searchable sheet).
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    this.label,
    this.required = false,
    required this.hint,
    required this.value,
    required this.onTap,
    this.icon = Icons.keyboard_arrow_down_rounded,
    this.errorText,
  });

  final String? label;
  final bool required;
  final String hint;
  final String? value;
  final VoidCallback onTap;
  final IconData icon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) FieldLabel(label!, required: required),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: InputDecorator(
            isEmpty: value == null,
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              suffixIcon: Icon(icon, color: AppColors.textSecondary),
            ),
            child: value == null
                ? null
                : Text(value!, style: AppText.input, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}
