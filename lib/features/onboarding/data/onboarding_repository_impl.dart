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

final onboardingRepositoryProvider = Provider<OnboardingRepository>((_) => PreviewOnboardingRepository());
final applicationStatusProvider =
    FutureProvider.autoDispose((ref) => ref.watch(onboardingRepositoryProvider).getApplicationStatus());
