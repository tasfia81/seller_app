import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';

/// One support conversation with the office (a question with a topic).
class SupportThread {
  const SupportThread({
    required this.id,
    required this.topic,
    required this.topicLabel,
    required this.resolved,
    required this.updatedAt,
    required this.messages,
    this.unread = 0,
  });

  final String id;
  final String topic;
  final String topicLabel;
  final bool resolved;
  final DateTime updatedAt;
  final List<SupportMessage> messages;
  final int unread;

  SupportMessage? get last => messages.isEmpty ? null : messages.last;
}

class SupportMessage {
  const SupportMessage({required this.fromOffice, required this.text, required this.at, this.author = ''});

  final bool fromOffice;
  final String text;
  final DateTime at;
  final String author;
}

class SupportTopic {
  const SupportTopic(this.id, this.label);
  final String id;
  final String label;
}

/// Same topics and ids as the server (`GET /support/topics` for a seller).
const sellerSupportTopics = [
  SupportTopic('stock', 'স্টক ও পণ্য'),
  SupportTopic('sales', 'বিক্রি ও হিসাব'),
  SupportTopic('cash', 'ক্যাশ ও পেমেন্ট'),
  SupportTopic('account', 'অ্যাকাউন্ট ও যাচাই'),
  SupportTopic('other', 'অন্য কিছু'),
];

/// Support chat. The server side is ready (`/support/*`); this app connects
/// to it once the seller login is connected. Until then the preview shows
/// sample conversations and never pretends a message was sent.
abstract interface class SupportRepository {
  bool get canSend;
  Future<List<SupportThread>> myThreads();
  Future<SupportThread> open(String id);
}

class PreviewSupportRepository implements SupportRepository {
  @override
  bool get canSend => false;

  static DateTime _at(int daysAgo, int h, int m) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day - daysAgo, h, m);
  }

  static final _threads = [
    SupportThread(
      id: 'demo-cash',
      topic: 'cash',
      topicLabel: 'ক্যাশ ও পেমেন্ট',
      resolved: false,
      unread: 1,
      updatedAt: _at(0, 11, 42),
      messages: [
        SupportMessage(fromOffice: false, text: 'আজ ৳৩০০ ক্যাশ জমা দিয়েছি, কিন্তু অ্যাপে এখনো যাচাই বাকি দেখাচ্ছে। একটু দেখবেন?', at: _at(0, 10, 15)),
        SupportMessage(fromOffice: true, author: 'সাপোর্ট টিম', text: 'দেখছি, একটু সময় দিন।', at: _at(0, 10, 21)),
        SupportMessage(
          fromOffice: true,
          author: 'সাপোর্ট টিম',
          text: 'আপনার ৳৩০০ পাওয়া গেছে, যাচাই হয়ে গেছে। “ক্যাশ জমা” পেজে এখন দেখতে পাবেন।',
          at: _at(0, 11, 42),
        ),
      ],
    ),
    SupportThread(
      id: 'demo-stock',
      topic: 'stock',
      topicLabel: 'স্টক ও পণ্য',
      resolved: true,
      updatedAt: _at(3, 17, 5),
      messages: [
        SupportMessage(fromOffice: false, text: 'জার্সি M সাইজ শেষ, আরও ১০টা পাওয়া যাবে?', at: _at(3, 16, 40)),
        SupportMessage(fromOffice: true, author: 'সাপোর্ট টিম', text: 'কাল সকালে নতুন বরাদ্দ দেওয়া হবে, অ্যাপে “পেয়েছি” চাপবেন।', at: _at(3, 16, 58)),
        SupportMessage(fromOffice: false, text: 'ধন্যবাদ, বুঝেছি।', at: _at(3, 17, 5)),
      ],
    ),
  ];

  @override
  Future<List<SupportThread>> myThreads() async {
    DemoData.ensureEnabled();
    return _threads;
  }

  @override
  Future<SupportThread> open(String id) async {
    DemoData.ensureEnabled();
    return _threads.firstWhere((t) => t.id == id);
  }
}

final supportRepositoryProvider = Provider<SupportRepository>((_) => PreviewSupportRepository());

final supportThreadsProvider = FutureProvider.autoDispose<List<SupportThread>>(
  (ref) => ref.watch(supportRepositoryProvider).myThreads(),
);

final supportThreadProvider = FutureProvider.autoDispose.family<SupportThread, String>(
  (ref, id) => ref.watch(supportRepositoryProvider).open(id),
);
