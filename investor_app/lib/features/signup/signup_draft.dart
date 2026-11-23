import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Everything typed during the 5 sign-up steps. Kept in memory only (never
/// saved to disk) and sent to the server in one go on the last step.
class SignupDraft {
  String mobile = '';

  // Step 2 — identity
  String fullName = '';
  DateTime? dateOfBirth;
  String occupation = '';
  String email = '';
  String fundsSource = '';
  String? division;
  String? district;
  String upazila = '';
  String addressDetail = '';
  String proposedAmount = '';
  String password = '';

  // Step 3 — KYC
  String nid = '';
  Uint8List? nidFront;
  Uint8List? nidBack;
  Uint8List? selfie;

  // Step 4 — payout & nominee
  String payoutMethod = 'bank'; // bank · bkash · nagad
  String accountName = '';
  String accountNumber = '';
  String bankName = '';
  String branch = '';
  String nomineeName = '';
  String nomineeRelation = '';
  String nomineeMobile = '';

  Map<String, Uint8List> get photos => {
        if (nidFront != null) 'nid_front': nidFront!,
        if (nidBack != null) 'nid_back': nidBack!,
        if (selfie != null) 'selfie': selfie!,
      };

  /// Body for `POST /investor/applications`.
  Map<String, dynamic> toJson() {
    String? opt(String v) => v.trim().isEmpty ? null : v.trim();
    final dob = dateOfBirth!;
    return {
      'full_name': fullName.trim(),
      'mobile': mobile,
      'date_of_birth': '${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
      'email': opt(email),
      'occupation': occupation,
      'funds_source': fundsSource,
      'address': {'division': division, 'district': district, 'upazila': upazila.trim(), 'detail': addressDetail.trim()},
      'nid_number': nid,
      'proposed_amount': double.parse(proposedAmount),
      'payout': {
        'method': payoutMethod,
        'account_name': accountName.trim(),
        'account_number': accountNumber.trim(),
        'bank_name': payoutMethod == 'bank' ? opt(bankName) : null,
        'branch': payoutMethod == 'bank' ? opt(branch) : null,
      },
      'nominee': {'name': nomineeName.trim(), 'relation': nomineeRelation, 'mobile': nomineeMobile},
      'password': password,
      'accepted_risk': true,
      'accepted_terms': true,
    };
  }
}

/// Lives until sign-up finishes; `ref.invalidate(signupDraftProvider)` wipes it.
final signupDraftProvider = Provider<SignupDraft>((ref) => SignupDraft());
