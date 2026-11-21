import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../shared/models/seller.dart';

abstract interface class ProfileRepository {
  Future<SellerProfile> getProfile();
}

class PreviewProfileRepository implements ProfileRepository {
  @override
  Future<SellerProfile> getProfile() async {
    DemoData.ensureEnabled();
    return DemoData.profile;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((_) => PreviewProfileRepository());
final profileProvider = FutureProvider.autoDispose((ref) => ref.watch(profileRepositoryProvider).getProfile());
