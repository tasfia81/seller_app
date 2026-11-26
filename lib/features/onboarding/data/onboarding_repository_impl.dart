import '../../../core/errors/failure.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_config.dart';
import '../../../shared/models/enums.dart';
import '../../auth/data/seller_session.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../shared/models/seller.dart';
import '../domain/registration.dart';

class PreviewOnboardingRepository implements OnboardingRepository {
  @override
  Future<String> submitApplication(SellerApplication application) async {
    DemoData.ensureEnabled();
    // Preview only: nothing is sent or stored. The seller gets NO permissions.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return DemoData.application.id;
  }

  @override
  Future<ApplicationInfo> getApplicationStatus() async {
    DemoData.ensureEnabled();
    return DemoData.application;
  }

  @override
  Future<void> resubmitDocument({required String field, required String filePath}) async {
    DemoData.ensureEnabled();
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) => AppConfig.previewAuth
    ? PreviewOnboardingRepository()
    : ApiOnboardingRepository(ref.watch(sellerSessionProvider)));
final applicationStatusProvider =
    FutureProvider.autoDispose((ref) => ref.watch(onboardingRepositoryProvider).getApplicationStatus());

class ApiOnboardingRepository implements OnboardingRepository {
  ApiOnboardingRepository(this.session);

  final SellerSession session;

  Map<String, String> _address(Address address) => {
    'division': address.division,
    'district': address.district,
    'upazila': address.upazila,
    'detail': address.detail,
  };

  @override
  Future<String> submitApplication(SellerApplication application) async {
    if (session.user != null &&
        (session.active || session.user?['mobile'] != application.mobile)) {
      throw const PermissionFailure();
    }
    if (session.user == null) {
      final response = await session.api.post('/seller/applications', {
        'full_name': application.fullName,
        'mobile': application.mobile,
        'otp_code': application.otpCode,
        'date_of_birth': application.dateOfBirth.toIso8601String().split('T').first,
        'gender': application.gender,
        'email': application.email,
        'guardian_name': application.guardianName,
        'present_address': _address(application.presentAddress),
        'permanent_address': _address(application.permanentAddress),
        'nid_number': application.nidNumber,
        'emergency': {
          'name': application.emergencyName,
          'relation': application.emergencyRelation,
          'mobile': application.emergencyMobile,
        },
        'password': application.password,
        'accepted_privacy': application.acceptedPrivacy,
        'accepted_terms': application.acceptedTerms,
      });
      await session.signIn(response as Map);
    }
    final applicationInfo = await session.api.get('/seller/application') as Map;
    final documents = applicationInfo['documents'] as Map;
    final files = {
      'nid_front': application.nidFrontPath,
      'nid_back': application.nidBackPath,
      'photo': application.photoPath,
    };
    for (final file in files.entries) {
      if ((documents[file.key] as Map)['uploaded'] != true) {
        await uploadDocument(file.key, file.value);
      }
    }
    return applicationInfo['id'] as String;
  }

  @override
  Future<ApplicationInfo> getApplicationStatus() async {
    final data = await session.api.get('/seller/application') as Map;
    final documents = data['documents'] as Map;
    final status = switch (data['status']) {
      'under_review' => ApplicationStatus.underReview,
      'more_info' => ApplicationStatus.moreInfoRequired,
      'approved' => ApplicationStatus.approved,
      'rejected' => ApplicationStatus.rejected,
      _ => ApplicationStatus.submitted,
    };
    return ApplicationInfo(
      id: data['id'] as String,
      status: status,
      submittedAt: DateTime.parse(data['submitted_at'] as String).toLocal(),
      adminMessage: data['admin_message'] as String?,
      rejectionReason: data['rejection_reason'] as String?,
      missingDocuments: [
        for (final field in documents.keys)
          if ((documents[field] as Map)['uploaded'] != true) field as String,
      ],
      requestedDocuments: List<String>.from(data['requested_fields'] as List),
      timeline: [
        for (final event in data['timeline'] as List)
          ApplicationTimelineStep(
            title: event['title'] as String,
            time: DateTime.tryParse(event['at'] as String)?.toLocal(),
            state: TimelineState.done,
          ),
      ],
    );
  }

  Future<void> requestOtp(String mobile) async {
    await session.api.post('/seller/application/otp', {'mobile': mobile});
  }

  Future<void> uploadDocument(String field, String filePath) async {
    final bytes = await XFile(filePath).readAsBytes();
    await session.api.upload('/seller/application/documents/$field', bytes, name: field);
  }

  Future<void> resubmit() async {
    await session.api.post('/seller/application/resubmit');
  }

  @override
  Future<void> resubmitDocument({required String field, required String filePath}) async {
    await uploadDocument(field, filePath);
    await resubmit();
  }
}
