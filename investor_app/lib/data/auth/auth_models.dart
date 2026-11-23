/// The signed-in user as the server describes it (`/auth/me`, login response).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.mobile,
    required this.status,
    this.email,
    this.investorId,
    this.applicationId,
  });

  final String id;
  final String name;
  final String mobile;
  final String? email;

  /// `applicant` · `active` · `rejected` (an approved investor is `active`).
  final String status;
  final String? investorId;
  final String? applicationId;

  /// Approved: the investor app proper is open.
  bool get isInvestor => investorId != null;

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: '${j['id']}',
        name: '${j['name'] ?? ''}',
        mobile: '${j['mobile'] ?? ''}',
        email: j['email'] as String?,
        status: '${j['status'] ?? ''}',
        investorId: j['investor_id'] as String?,
        applicationId: j['application_id'] as String?,
      );
}

/// Application (KYC) status as returned by `GET /investor/application`.
class ApplicationStatus {
  const ApplicationStatus({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.fullName,
    required this.submittedAt,
    required this.documents,
    required this.requestedFields,
    required this.timeline,
    this.adminMessage,
    this.rejectionReason,
  });

  final String id;

  /// submitted · under_review · more_info · approved · rejected
  final String status;
  final String statusLabel;
  final String fullName;
  final DateTime submittedAt;

  /// `nid_front` / `nid_back` / `selfie` → uploaded?
  final Map<String, bool> documents;
  final List<String> requestedFields;
  final List<TimelineEntry> timeline;
  final String? adminMessage;
  final String? rejectionReason;

  List<String> get missingDocuments => [for (final e in documents.entries) if (!e.value) e.key];

  factory ApplicationStatus.fromJson(Map<String, dynamic> j) => ApplicationStatus(
        id: '${j['id']}',
        status: '${j['status']}',
        statusLabel: '${j['status_label'] ?? ''}',
        fullName: '${j['full_name'] ?? ''}',
        submittedAt: DateTime.tryParse('${j['submitted_at']}')?.toLocal() ?? DateTime.now(),
        documents: {
          for (final e in ((j['documents'] as Map?) ?? const {}).entries) '${e.key}': e.value == true,
        },
        requestedFields: [for (final f in (j['requested_fields'] as List?) ?? const []) '$f'],
        timeline: [
          for (final t in (j['timeline'] as List?) ?? const [])
            if (t is Map) TimelineEntry.fromJson(Map<String, dynamic>.from(t)),
        ],
        adminMessage: j['admin_message'] as String?,
        rejectionReason: j['rejection_reason'] as String?,
      );
}

class TimelineEntry {
  const TimelineEntry({required this.title, required this.at, required this.by});

  final String title;
  final DateTime at;
  final String by;

  factory TimelineEntry.fromJson(Map<String, dynamic> j) => TimelineEntry(
        title: '${j['title'] ?? ''}',
        at: DateTime.tryParse('${j['at']}')?.toLocal() ?? DateTime.now(),
        by: '${j['by'] ?? ''}',
      );
}

/// KYC photo kinds the server accepts.
abstract final class DocKind {
  static const nidFront = 'nid_front';
  static const nidBack = 'nid_back';
  static const selfie = 'selfie';
  static const all = [nidFront, nidBack, selfie];

  static String label(String kind) => switch (kind) {
        nidFront => 'NID-এর সামনের দিক',
        nidBack => 'NID-এর পেছনের দিক',
        selfie => 'সেলফি',
        'payout' => 'লাভ পাঠানোর অ্যাকাউন্ট',
        'nominee' => 'নমিনির তথ্য',
        'address' => 'ঠিকানা',
        _ => kind,
      };
}
