import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../auth/auth_repository.dart';

/// One support conversation (a question to the office, with a topic).
class SupportThread {
  const SupportThread({
    required this.id,
    required this.topic,
    required this.topicLabel,
    required this.status,
    required this.statusLabel,
    required this.updatedAt,
    required this.lastMessage,
    required this.lastFromOffice,
    required this.unread,
    this.messages = const [],
  });

  final String id;
  final String topic;
  final String topicLabel;

  /// `open` · `resolved`
  final String status;
  final String statusLabel;
  final DateTime updatedAt;
  final String lastMessage;
  final bool lastFromOffice;
  final int unread;
  final List<SupportMessage> messages;

  bool get resolved => status == 'resolved';

  factory SupportThread.fromJson(Map<String, dynamic> j) => SupportThread(
        id: '${j['id']}',
        topic: '${j['topic']}',
        topicLabel: '${j['topic_label'] ?? ''}',
        status: '${j['status']}',
        statusLabel: '${j['status_label'] ?? ''}',
        updatedAt: DateTime.tryParse('${j['updated_at']}')?.toLocal() ?? DateTime.now(),
        lastMessage: '${j['last_message'] ?? ''}',
        lastFromOffice: j['last_from'] == 'admin',
        unread: (j['unread'] as num?)?.toInt() ?? 0,
        messages: [
          for (final m in (j['messages'] as List?) ?? const [])
            if (m is Map) SupportMessage.fromJson(Map<String, dynamic>.from(m)),
        ],
      );
}

class SupportMessage {
  const SupportMessage({required this.id, required this.fromOffice, required this.author, required this.text, required this.at});

  final String id;
  final bool fromOffice;
  final String author;
  final String text;
  final DateTime at;

  factory SupportMessage.fromJson(Map<String, dynamic> j) => SupportMessage(
        id: '${j['id']}',
        fromOffice: j['sender'] == 'admin',
        author: '${j['author'] ?? ''}',
        text: '${j['text'] ?? ''}',
        at: DateTime.tryParse('${j['at']}')?.toLocal() ?? DateTime.now(),
      );
}

class SupportTopic {
  const SupportTopic(this.id, this.label);
  final String id;
  final String label;
}

final supportRepositoryProvider = Provider<SupportRepository>((ref) => SupportRepository(ref.watch(apiClientProvider)));

/// My conversations (refreshed when the support screen opens or is pulled).
final supportThreadsProvider = FutureProvider.autoDispose<List<SupportThread>>(
  (ref) => ref.watch(supportRepositoryProvider).myThreads(),
);

final supportTopicsProvider = FutureProvider.autoDispose<List<SupportTopic>>(
  (ref) => ref.watch(supportRepositoryProvider).topics(),
);

/// Support chat calls (`/support/*`). Works for applicants too, so a question
/// can be asked while the application is still being checked.
class SupportRepository {
  SupportRepository(this._api);

  final ApiClient _api;
  static final _rand = Random.secure();

  /// Idempotency key: a retried send is stored only once.
  static String newRequestId() => List.generate(24, (_) => _rand.nextInt(36).toRadixString(36)).join();

  Future<List<SupportTopic>> topics() async => [
        for (final t in (await _api.get('/support/topics') as List))
          if (t is Map) SupportTopic('${t['id']}', '${t['label']}'),
      ];

  Future<List<SupportThread>> myThreads() async => [
        for (final t in (await _api.get('/support/threads') as List))
          if (t is Map) SupportThread.fromJson(Map<String, dynamic>.from(t)),
      ];

  /// Opening a thread also marks the office's replies as read.
  Future<SupportThread> open(String id) async =>
      SupportThread.fromJson(Map<String, dynamic>.from(await _api.get('/support/threads/${Uri.encodeComponent(id)}') as Map));

  Future<SupportThread> start(String topic, String text, String requestId) async => SupportThread.fromJson(Map<String, dynamic>.from(
      await _api.post('/support/threads', {'topic': topic, 'text': text, 'client_request_id': requestId}) as Map));

  Future<SupportThread> send(String id, String text, String requestId) async => SupportThread.fromJson(Map<String, dynamic>.from(
      await _api.post('/support/threads/${Uri.encodeComponent(id)}/messages', {'text': text, 'client_request_id': requestId}) as Map));
}
