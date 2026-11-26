import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/utils/bn_format.dart';
import '../../core/utils/validators.dart';
import '../../data/auth/auth_repository.dart';

class PasswordResetDialog extends ConsumerStatefulWidget {
  const PasswordResetDialog({super.key, required this.initialMobile});

  final String initialMobile;

  @override
  ConsumerState<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends ConsumerState<PasswordResetDialog> {
  late final _mobile = TextEditingController(text: widget.initialMobile);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  String? _sentTo;
  bool _busy = false;

  @override
  void dispose() {
    _mobile.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _run({required bool reset}) async {
    final mobile = Validators.mobile(_mobile.text);
    if (mobile == null) {
      setState(() => _error = 'সঠিক মোবাইল নম্বর দিন।');
      return;
    }
    final code = BnFormat.toAscii(_code.text.trim());
    final password = _password.text;
    if (reset && (!RegExp(r'^[0-9]{6}$').hasMatch(code) ||
        password.length < 8 || !RegExp(r'[0-9]').hasMatch(password) || password != _confirm.text)) {
      setState(() => _error = '৬ সংখ্যার কোড এবং সংখ্যা-সহ অন্তত ৮ অক্ষরের মিল থাকা পাসওয়ার্ড দিন।');
      return;
    }
    setState(() { _busy = true; _error = null; });
    final repository = ref.read(authRepositoryProvider);
    try {
      if (reset) {
        await repository.resetPassword(mobile, code, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('পাসওয়ার্ড পরিবর্তন হয়েছে।')));
          Navigator.of(context).pop();
        }
      } else {
        await repository.requestPasswordOtp(mobile);
        if (mounted) setState(() => _sentTo = mobile);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('পাসওয়ার্ড পুনরুদ্ধার'),
    scrollable: true,
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _mobile, keyboardType: TextInputType.phone,
        enabled: _sentTo == null && !_busy, decoration: const InputDecoration(labelText: 'মোবাইল নম্বর')),
      if (_sentTo != null) ...[
        const Text('নিবন্ধিত নম্বর হলে SMS কোড পাঠানো হয়েছে।'),
        TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6,
          decoration: const InputDecoration(labelText: 'SMS কোড')),
        TextField(controller: _password, obscureText: true,
          decoration: const InputDecoration(labelText: 'নতুন পাসওয়ার্ড')),
        TextField(controller: _confirm, obscureText: true,
          decoration: const InputDecoration(labelText: 'পাসওয়ার্ড আবার লিখুন')),
      ],
      if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    ]),
    actions: [
      TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: const Text('বন্ধ')),
      if (_sentTo != null)
        TextButton(onPressed: _busy ? null : () => _run(reset: false), child: const Text('আবার কোড পাঠান')),
      FilledButton(onPressed: _busy ? null : () => _run(reset: _sentTo != null),
        child: Text(_sentTo == null ? 'SMS কোড পাঠান' : 'পাসওয়ার্ড বদলান')),
    ],
  );
}
