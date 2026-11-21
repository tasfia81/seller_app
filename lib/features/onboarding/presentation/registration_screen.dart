import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/bd_locations.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/image_upload_card.dart';
import '../../../core/widgets/inputs.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/presentation/forgot_password_screen.dart' show PasswordStrength;
import '../data/onboarding_repository_impl.dart';
import '../domain/registration.dart';

final _digitsOnly = [FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯]'))];

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  static const _titles = ['ব্যক্তিগত তথ্য', 'পরিচয় যাচাই', 'জরুরি যোগাযোগ', 'অ্যাকাউন্ট নিরাপত্তা', 'তথ্য যাচাই ও জমা'];
  static const _genders = ['পুরুষ', 'নারী', 'অন্যান্য'];
  static const _relations = ['বাবা', 'মা', 'ভাই', 'বোন', 'স্বামী/স্ত্রী', 'অন্যান্য'];

  int _step = 0;
  bool _submitting = false;
  final _forms = List.generate(4, (_) => GlobalKey<FormState>());
  final _tried = List.filled(5, false);
  final _scrolls = List.generate(5, (_) => ScrollController());

  // Step 1
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _guardian = TextEditingController();
  DateTime? _dob;
  String? _gender;
  final _present = _AddressState();
  final _permanent = _AddressState();
  bool _sameAddress = true;

  // Step 2
  final _nid = TextEditingController();
  XFile? _nidFront, _nidBack, _photo;

  // Step 3
  final _emName = TextEditingController();
  final _emMobile = TextEditingController();
  String? _relation;

  // Step 4
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  // Step 5
  bool _privacy = false, _terms = false;

  @override
  void dispose() {
    for (final c in [_name, _mobile, _email, _guardian, _nid, _emName, _emMobile, _pass, _confirm, ..._scrolls]) {
      c.dispose();
    }
    _present.dispose();
    _permanent.dispose();
    super.dispose();
  }

  bool _validateStep(int s) {
    if (AppConfig.skipAuthValidation) return true;
    setState(() => _tried[s] = true);
    final formOk = s < 4 ? _forms[s].currentState!.validate() : true;
    return switch (s) {
      0 => formOk &&
          Validators.dateOfBirth(_dob) == null &&
          _present.isComplete &&
          (_sameAddress || _permanent.isComplete),
      1 => formOk && _nidFront != null && _nidBack != null && _photo != null,
      2 => formOk && _relation != null,
      3 => formOk,
      _ => _privacy && _terms,
    };
  }

  void _goTo(int s) {
    FocusScope.of(context).unfocus();
    setState(() => _step = s);
  }

  void _next() {
    if (!_validateStep(_step)) {
      showAppSnack(context, 'লাল চিহ্নিত ঘরগুলো ঠিক করুন।', error: true);
      return;
    }
    if (_step < 4) {
      _goTo(_step + 1);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    for (var s = 0; s < 4; s++) {
      if (!_validateStep(s)) {
        _goTo(s);
        showAppSnack(context, 'এই ধাপের তথ্য ঠিক করুন।', error: true);
        return;
      }
    }
    // Validation is off for the UI phase: with missing data there is nothing
    // to send, so just continue to the next screen.
    if (_dob == null || _nidFront == null || _nidBack == null || _photo == null || _relation == null) {
      context.go(AppRoutes.applicationSubmitted);
      return;
    }
    setState(() => _submitting = true);
    try {
      final present = _present.toAddress();
      await ref.read(onboardingRepositoryProvider).submitApplication(SellerApplication(
            fullName: _name.text.trim(),
            mobile: Validators.normalizePhone(_mobile.text),
            dateOfBirth: _dob!,
            gender: _gender,
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            guardianName: _guardian.text.trim().isEmpty ? null : _guardian.text.trim(),
            presentAddress: present,
            permanentAddress: _sameAddress ? present : _permanent.toAddress(),
            nidNumber: BnFormat.toAscii(_nid.text).replaceAll(RegExp(r'\D'), ''),
            nidFrontPath: _nidFront!.path,
            nidBackPath: _nidBack!.path,
            photoPath: _photo!.path,
            emergencyName: _emName.text.trim(),
            emergencyRelation: _relation!,
            emergencyMobile: Validators.normalizePhone(_emMobile.text),
            password: _pass.text,
            acceptedPrivacy: _privacy,
            acceptedTerms: _terms,
          ));
      if (mounted) context.go(AppRoutes.applicationSubmitted);
    } catch (e) {
      if (mounted) showAppSnack(context, failureMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _onBack() async {
    if (_step > 0) {
      _goTo(_step - 1);
      return;
    }
    final leave = await showConfirmDialog(context,
        title: 'আবেদন ছেড়ে যাবেন?',
        message: 'এখন বের হলে দেওয়া তথ্যগুলো মুছে যাবে।',
        confirmLabel: 'বের হন',
        cancelLabel: 'থাকুন',
        destructive: true);
    if (leave && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'পেছনে যান',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _onBack,
          ),
          title: Text(_titles[_step]),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(child: Text('ধাপ ${BnFormat.digits('${_step + 1}')}/৫', style: AppText.caption)),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(16),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12),
              child: StepProgress(total: 5, current: _step + 1),
            ),
          ),
        ),
        body: IndexedStack(
          index: _step,
          children: [
            _page(0, Form(key: _forms[0], child: _personal())),
            _page(1, Form(key: _forms[1], child: _identity())),
            _page(2, Form(key: _forms[2], child: _emergency())),
            _page(3, Form(key: _forms[3], child: _security())),
            _page(4, _review()),
          ],
        ),
        bottomNavigationBar: BottomActionBar(
          child: AppButton(
            label: _step == 4 ? 'আবেদন জমা দিন' : 'পরবর্তী ধাপ',
            loading: _submitting,
            onPressed:
                _step == 4 && !AppConfig.skipAuthValidation && !(_privacy && _terms) ? null : _next,
          ),
        ),
      ),
    );
  }

  Widget _page(int i, Widget child) => SingleChildScrollView(
        controller: _scrolls[i],
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        child: child,
      );

  Widget _gap([double h = 14]) => SizedBox(height: h.h);

  // ---------- Step 1 ----------
  Widget _personal() {
    final dobError = _tried[0] ? Validators.dateOfBirth(_dob) : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppTextField(
        label: 'পূর্ণ নাম',
        required: true,
        controller: _name,
        hint: 'জাতীয় পরিচয়পত্র অনুযায়ী নাম',
        textInputAction: TextInputAction.next,
        validator: Validators.auth((v) => Validators.required(v, 'পূর্ণ নাম দিন।')),
      ),
      _gap(),
      AppTextField(
        label: 'মোবাইল নম্বর',
        required: true,
        controller: _mobile,
        hint: '01XXXXXXXXX',
        prefixText: '+৮৮০  ',
        keyboardType: TextInputType.phone,
        inputFormatters: [..._digitsOnly, LengthLimitingTextInputFormatter(11)],
        validator: Validators.auth(Validators.mobile),
      ),
      _gap(),
      PickerField(
        label: 'জন্মতারিখ',
        required: true,
        hint: 'দিন / মাস / বছর',
        value: _dob == null ? null : BnFormat.dateFull(_dob!),
        icon: Icons.calendar_month_outlined,
        errorText: dobError,
        onTap: _pickDob,
      ),
      _gap(),
      const FieldLabel('লিঙ্গ', optional: true),
      ChoicePills<String>(
        options: _genders,
        selected: _gender,
        labelOf: (g) => g,
        onSelected: (g) => setState(() => _gender = _gender == g ? null : g),
      ),
      _gap(),
      AppTextField(
        label: 'ইমেইল',
        optional: true,
        controller: _email,
        hint: 'example@mail.com',
        keyboardType: TextInputType.emailAddress,
        validator: Validators.auth(Validators.email),
      ),
      _gap(),
      AppTextField(label: 'পিতা বা মাতার নাম', optional: true, controller: _guardian, hint: 'নাম লিখুন'),
      _gap(22),
      _AddressFields(title: 'বর্তমান ঠিকানা', state: _present, showErrors: _tried[0], onChanged: () => setState(() {})),
      _gap(8),
      CheckRow(
        value: _sameAddress,
        onChanged: (v) => setState(() => _sameAddress = v),
        child: Text('স্থায়ী ঠিকানা বর্তমান ঠিকানার মতোই', style: AppText.body),
      ),
      if (!_sameAddress) ...[
        _gap(8),
        _AddressFields(
            title: 'স্থায়ী ঠিকানা', state: _permanent, showErrors: _tried[0], onChanged: () => setState(() {})),
      ],
    ]);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 80),
      lastDate: now,
      helpText: 'জন্মতারিখ বাছুন',
      initialEntryMode: DatePickerEntryMode.calendar,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  // ---------- Step 2 ----------
  Widget _identity() {
    final t = _tried[1];
    String? need(XFile? f) => t && f == null ? 'এই ছবিটি দিতে হবে।' : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      InfoBanner(
        icon: Icons.shield_outlined,
        text: 'কোম্পানির পণ্য ও টাকা আপনার কাছে থাকবে, তাই পরিচয় নিশ্চিত করা জরুরি। তথ্য সুরক্ষিত থাকবে, '
            'শুধু অনুমোদিত অ্যাডমিন দেখতে পারবেন।',
        child: TextButton(
          onPressed: () => _showPrivacy(context),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(48, 36)),
          child: const Text('গোপনীয়তা নীতি পড়ুন', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      _gap(),
      AppTextField(
        label: 'জাতীয় পরিচয়পত্র নম্বর',
        required: true,
        controller: _nid,
        hint: '১০, ১৩ বা ১৭ সংখ্যার নম্বর',
        keyboardType: TextInputType.number,
        inputFormatters: [..._digitsOnly, LengthLimitingTextInputFormatter(17)],
        validator: Validators.auth(Validators.nid),
      ),
      _gap(),
      const _CaptureTips(),
      _gap(),
      ImageUploadCard(
        title: 'পরিচয়পত্রের সামনের ছবি',
        icon: Icons.badge_outlined,
        file: _nidFront,
        errorText: need(_nidFront),
        onPicked: (f) => setState(() => _nidFront = f),
        onRemove: () => setState(() => _nidFront = null),
      ),
      _gap(10),
      ImageUploadCard(
        title: 'পরিচয়পত্রের পেছনের ছবি',
        icon: Icons.badge_outlined,
        file: _nidBack,
        errorText: need(_nidBack),
        onPicked: (f) => setState(() => _nidBack = f),
        onRemove: () => setState(() => _nidBack = null),
      ),
      _gap(10),
      ImageUploadCard(
        title: 'আপনার একটি পরিষ্কার ছবি দিন',
        icon: Icons.face_outlined,
        circular: true,
        frontCamera: true,
        file: _photo,
        errorText: need(_photo),
        onPicked: (f) => setState(() => _photo = f),
        onRemove: () => setState(() => _photo = null),
      ),
      _gap(8),
      Text('মুখ পরিষ্কার দেখা যায় এমন সাম্প্রতিক ছবি দিন। ছবি অ্যাডমিন নিজে যাচাই করবেন।', style: AppText.small),
    ]);
  }

  // ---------- Step 3 ----------
  Widget _emergency() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const InfoBanner(
        text: 'এমন একজনের তথ্য দিন যাকে বিপদের সময় জানানো যাবে। শুধু সত্যিকারের জরুরি প্রয়োজনে যোগাযোগ করা হবে।',
      ),
      _gap(),
      AppTextField(
        label: 'নাম',
        required: true,
        controller: _emName,
        hint: 'পূর্ণ নাম',
        validator: Validators.auth((v) => Validators.required(v, 'নাম দিন।')),
      ),
      _gap(),
      const FieldLabel('সম্পর্ক', required: true),
      ChoicePills<String>(
        options: _relations,
        selected: _relation,
        labelOf: (r) => r,
        onSelected: (r) => setState(() => _relation = r),
      ),
      if (_tried[2] && _relation == null)
        Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Text('সম্পর্ক বাছুন।', style: TextStyle(fontSize: 13.sp, color: const Color(0xFFC23B3B))),
        ),
      _gap(),
      AppTextField(
        label: 'মোবাইল নম্বর',
        required: true,
        controller: _emMobile,
        hint: '01XXXXXXXXX',
        prefixText: '+৮৮০  ',
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        inputFormatters: [..._digitsOnly, LengthLimitingTextInputFormatter(11)],
        validator: Validators.auth((v) {
          final base = Validators.mobile(v);
          if (base != null) return base;
          return Validators.normalizePhone(v!) == Validators.normalizePhone(_mobile.text)
              ? 'নিজের নম্বর ছাড়া অন্য একটি নম্বর দিন।'
              : null;
        }),
      ),
    ]);
  }

  // ---------- Step 4 ----------
  Widget _security() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('লগইনের জন্য একটি পাসওয়ার্ড তৈরি করুন। এটি কাউকে জানাবেন না।', style: AppText.caption.copyWith(fontSize: 14.sp)),
      _gap(),
      PasswordField(
        label: 'পাসওয়ার্ড',
        required: true,
        controller: _pass,
        onChanged: (_) => setState(() {}),
        validator: Validators.auth(Validators.password),
      ),
      _gap(10),
      PasswordStrength(password: _pass.text),
      _gap(),
      PasswordField(
        label: 'পাসওয়ার্ড আবার লিখুন',
        required: true,
        controller: _confirm,
        textInputAction: TextInputAction.done,
        validator: Validators.auth((v) => Validators.confirm(v, _pass.text)),
      ),
    ]);
  }

  // ---------- Step 5 ----------
  Widget _review() {
    final present = _present.isComplete ? _present.toAddress().display : '—';
    Widget section(String title, int step, List<Widget> rows) => Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: AppCard(
            padding: EdgeInsets.fromLTRB(14.w, 6.h, 6.w, 8.h),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text(title, style: AppText.section)),
                TextButton(
                  onPressed: () => _goTo(step),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                  child: const Text('সম্পাদনা', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ]),
              Padding(padding: EdgeInsets.only(right: 8.w), child: Column(children: rows)),
            ]),
          ),
        );
    Widget doc(String label, XFile? f) => KeyValueRow(label, '',
        valueWidget: Align(
          alignment: Alignment.centerRight,
          child: StatusChip(f == null ? 'বাকি' : 'দেওয়া হয়েছে', tone: f == null ? ChipTone.error : ChipTone.success),
        ));
    final nidDigits = BnFormat.toAscii(_nid.text).replaceAll(RegExp(r'\D'), '');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      section('ব্যক্তিগত তথ্য', 0, [
        KeyValueRow('নাম', _name.text.isEmpty ? '—' : _name.text),
        KeyValueRow('মোবাইল', _mobile.text.isEmpty ? '—' : BnFormat.phone(_mobile.text)),
        KeyValueRow('জন্মতারিখ', _dob == null ? '—' : BnFormat.dateFull(_dob!)),
        KeyValueRow('বর্তমান ঠিকানা', present, divider: false),
      ]),
      section('পরিচয় ডকুমেন্ট', 1, [
        KeyValueRow('পরিচয়পত্র নম্বর', nidDigits.isEmpty ? '—' : BnFormat.maskNid(nidDigits)),
        doc('সামনের ছবি', _nidFront),
        doc('পেছনের ছবি', _nidBack),
        doc('সেলারের ছবি', _photo),
      ]),
      section('জরুরি যোগাযোগ', 2, [
        KeyValueRow(
          _emName.text.isEmpty ? '—' : '${_emName.text}${_relation == null ? '' : ' ($_relation)'}',
          _emMobile.text.isEmpty ? '—' : BnFormat.phone(_emMobile.text),
          divider: false,
        ),
      ]),
      section('অ্যাকাউন্ট', 3, [
        KeyValueRow('পাসওয়ার্ড', _pass.text.isEmpty ? 'দেওয়া হয়নি' : 'সেট করা হয়েছে', divider: false),
      ]),
      SizedBox(height: 4.h),
      CheckRow(
        value: _privacy,
        onChanged: (v) => setState(() => _privacy = v),
        child: Text.rich(TextSpan(style: AppText.body, children: [
          const TextSpan(text: 'আমি '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => _showPrivacy(context),
              child: Text('গোপনীয়তা নীতি',
                  style: AppText.body.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
            ),
          ),
          const TextSpan(text: ' পড়েছি এবং পরিচয় যাচাইয়ের জন্য তথ্য দিতে সম্মত।'),
        ])),
      ),
      CheckRow(
        value: _terms,
        onChanged: (v) => setState(() => _terms = v),
        child: Text('আমি কাজের শর্তাবলি মেনে নিচ্ছি।', style: AppText.body),
      ),
    ]);
  }
}

Future<void> _showPrivacy(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
          children: [
            Text('গোপনীয়তা নীতি — সারসংক্ষেপ', style: AppText.section.copyWith(fontSize: 17.sp)),
            SizedBox(height: 12.h),
            for (final line in const [
              'পরিচয়পত্র ও ছবি নেওয়া হয় শুধু আপনার পরিচয় নিশ্চিত করার জন্য।',
              'এসব তথ্য সুরক্ষিত সার্ভারে রাখা হয়, শুধু অনুমোদিত অ্যাডমিন দেখতে পারেন।',
              'আপনার ফোনের গ্যালারিতে পরিচয়পত্রের ছবি নিজে থেকে সেভ করা হয় না।',
              'অ্যাপে পরে পরিচয়পত্রের পুরো নম্বর দেখানো হয় না।',
              'কাজ শেষ হলে নীতিমালা অনুযায়ী তথ্য মুছে ফেলার অনুরোধ করতে পারবেন।',
            ])
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.primary),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(child: Text(line, style: AppText.body)),
                ]),
              ),
            Text('সম্পূর্ণ নীতিমালা ব্যাকএন্ড চালু হওয়ার সময় যুক্ত হবে।', style: AppText.small),
          ],
        ),
      ),
    );

class _CaptureTips extends StatelessWidget {
  const _CaptureTips();

  @override
  Widget build(BuildContext context) {
    const tips = ['ছবি পরিষ্কার হতে হবে', 'কার্ডের চার কোণা দৃশ্যমান', 'পর্যাপ্ত আলো', 'লেখা যেন ঝাপসা না হয়'];
    return Wrap(
      spacing: 12.w,
      runSpacing: 6.h,
      children: [
        for (final t in tips)
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
            SizedBox(width: 4.w),
            Text(t, style: AppText.small.copyWith(color: AppColors.textBody)),
          ]),
      ],
    );
  }
}

class _AddressState {
  String? division;
  String? district;
  final upazila = TextEditingController();
  final detail = TextEditingController();

  bool get isComplete =>
      division != null && district != null && upazila.text.trim().isNotEmpty && detail.text.trim().isNotEmpty;

  Address toAddress() => Address(
      division: division ?? '', district: district ?? '', upazila: upazila.text.trim(), detail: detail.text.trim());

  void dispose() {
    upazila.dispose();
    detail.dispose();
  }
}

class _AddressFields extends StatelessWidget {
  const _AddressFields({required this.title, required this.state, required this.showErrors, required this.onChanged});

  final String title;
  final _AddressState state;
  final bool showErrors;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final districts = state.division == null ? const <String>[] : bdDistricts[state.division]!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FieldLabel(title, required: true),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: PickerField(
            hint: 'বিভাগ',
            value: state.division,
            errorText: showErrors && state.division == null ? 'বিভাগ বাছুন' : null,
            onTap: () async {
              final v = await showSearchSheet<String>(context,
                  title: 'বিভাগ বাছুন', items: bdDistricts.keys.toList(), labelOf: (s) => s);
              if (v != null && v != state.division) {
                state
                  ..division = v
                  ..district = null;
                onChanged();
              }
            },
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: PickerField(
            hint: 'জেলা',
            value: state.district,
            errorText: showErrors && state.district == null ? 'জেলা বাছুন' : null,
            onTap: () async {
              if (state.division == null) {
                showAppSnack(context, 'আগে বিভাগ বাছুন।');
                return;
              }
              final v = await showSearchSheet<String>(context,
                  title: 'জেলা বাছুন', items: districts, labelOf: (s) => s);
              if (v != null) {
                state.district = v;
                onChanged();
              }
            },
          ),
        ),
      ]),
      SizedBox(height: 10.h),
      AppTextField(
        controller: state.upazila,
        hint: 'উপজেলা / থানা',
        validator: Validators.auth((v) => Validators.required(v, 'উপজেলা বা থানা লিখুন।')),
      ),
      SizedBox(height: 10.h),
      AppTextField(
        controller: state.detail,
        hint: 'বাড়ি, রাস্তা, এলাকা',
        validator: Validators.auth((v) => Validators.required(v, 'বিস্তারিত ঠিকানা লিখুন।')),
      ),
    ]);
  }
}
