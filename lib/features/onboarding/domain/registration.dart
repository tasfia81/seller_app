import '../../../shared/models/seller.dart';

/// Typed application payload sent to the backend. Images are referenced by
/// local file path and must be uploaded to private, authenticated storage.
class Address {
  const Address({required this.division, required this.district, required this.upazila, required this.detail});
  final String division;
  final String district;
  final String upazila;
  final String detail;

  String get display => '$detail, $upazila, $district';
}

class SellerApplication {
  const SellerApplication({
    required this.fullName,
    required this.mobile,
    required this.dateOfBirth,
    required this.presentAddress,
    required this.permanentAddress,
    required this.nidNumber,
    required this.nidFrontPath,
    required this.nidBackPath,
    required this.photoPath,
    required this.emergencyName,
    required this.emergencyRelation,
    required this.emergencyMobile,
    required this.password,
    required this.acceptedPrivacy,
    required this.acceptedTerms,
    this.gender,
    this.email,
    this.guardianName,
  });

  final String fullName;
  final String mobile;
  final DateTime dateOfBirth;
  final String? gender;
  final String? email;
  final String? guardianName;
  final Address presentAddress;
  final Address permanentAddress;
  final String nidNumber;
  final String nidFrontPath;
  final String nidBackPath;
  final String photoPath;
  final String emergencyName;
  final String emergencyRelation;
  final String emergencyMobile;
  final String password;
  final bool acceptedPrivacy;
  final bool acceptedTerms;
}

abstract interface class OnboardingRepository {
  Future<String> submitApplication(SellerApplication application);
  Future<ApplicationInfo> getApplicationStatus();

  /// Re-submit only what the admin asked for (e.g. one blurry photo).
  Future<void> resubmitDocument({required String field, required String filePath});
}
