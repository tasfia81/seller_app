import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../core/errors/failure.dart';
import '../../../shared/models/finance.dart';

abstract interface class DayClosingRepository {
  Future<DayClosingSummary> getToday();
  Future<void> submitClosing();
}

class PreviewDayClosingRepository implements DayClosingRepository {
  @override
  Future<DayClosingSummary> getToday() async {
    DemoData.ensureEnabled();
    return DemoData.dayClosing;
  }

  @override
  Future<void> submitClosing() async => throw const NotConnectedFailure();
}

final dayClosingRepositoryProvider = Provider<DayClosingRepository>((_) => PreviewDayClosingRepository());
final dayClosingProvider =
    FutureProvider.autoDispose((ref) => ref.watch(dayClosingRepositoryProvider).getToday());
