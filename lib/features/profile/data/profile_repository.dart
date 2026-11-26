import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/seller_payload.dart';
import '../../../core/constants/app_config.dart';
import '../../auth/data/seller_session.dart';
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

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => AppConfig.previewAuth
    ? PreviewProfileRepository()
    : ApiProfileRepository(ref.watch(sellerSessionProvider).api));
final profileProvider = FutureProvider.autoDispose((ref) => ref.watch(profileRepositoryProvider).getProfile());

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this.api);
  final ApiClient api;

  @override
  Future<SellerProfile> getProfile() async => parseProfile(jsonMap(await api.get('/seller/profile')));

  Future<void> requestChange(String field, String value) async {
    await api.post('/seller/profile/change-requests', {'field': field, 'new_value': value});
  }
}
