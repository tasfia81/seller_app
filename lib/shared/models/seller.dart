import 'enums.dart';

class SellerProfile {
  const SellerProfile({
    required this.name,
    required this.mobile,
    required this.presentAddress,
    required this.permanentAddress,
    required this.emergencyContact,
    required this.maskedNid,
    required this.isVerified,
    required this.isActive,
    this.photoUrl,
  });

  final String name;
  final String mobile;
  final String presentAddress;
  final String permanentAddress;
  final String emergencyContact;

  /// Only the masked form ever reaches the UI.
  final String maskedNid;
  final bool isVerified;
  final bool isActive;
  final String? photoUrl;

  /// First letter plus any following Bangla vowel sign (e.g. "রা").
  String get initials {
    final runes = name.trim().runes.toList();
    if (runes.isEmpty) return '?';
    final out = [runes.first];
    if (runes.length > 1 && runes[1] >= 0x09BE && runes[1] <= 0x09CC) out.add(runes[1]);
    return String.fromCharCodes(out);
  }
}

class ApplicationTimelineStep {
  const ApplicationTimelineStep({required this.title, this.time, required this.state});
  final String title;
  final DateTime? time;
  final TimelineState state;
}

enum TimelineState { done, current, attention, upcoming }

class ApplicationInfo {
  const ApplicationInfo({
    required this.id,
    required this.status,
    required this.submittedAt,
    required this.timeline,
    this.adminMessage,
    this.rejectionReason,
  });

  final String id;
  final ApplicationStatus status;
  final DateTime submittedAt;
  final List<ApplicationTimelineStep> timeline;
  final String? adminMessage;
  final String? rejectionReason;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;

  AppNotification markRead() =>
      AppNotification(id: id, type: type, title: title, body: body, time: time, isRead: true);
}
