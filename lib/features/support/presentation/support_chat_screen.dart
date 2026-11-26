import '../../../core/errors/failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../data/support_repository.dart';
import 'support_home_screen.dart';

/// Chat with the office: an existing conversation ([threadId]) or a new
/// question on a [topic].
class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key, this.threadId, this.topic, this.topicLabel});

  final String? threadId;
  final String? topic;
  final String? topicLabel;

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  static const _quick = ['ধন্যবাদ, বুঝেছি', 'আরেকটু বুঝিয়ে বলবেন?', 'ফোনে কথা বলতে চাই'];
  final _text = TextEditingController();
  String? _threadId;
  String? _lastBody;
  String? _requestId;
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final body = (preset ?? _text.text).trim();
    if (body.isEmpty || _sending) return;
    final repo = ref.read(supportRepositoryProvider);
    if (repo is! ApiSupportRepository) {
      showAppSnack(context, 'প্রিভিউ মোডে বার্তা পাঠানো যায় না।', error: true);
      return;
    }
    if (_lastBody != body || _requestId == null) {
      _lastBody = body;
      _requestId = 'chat-${DateTime.now().microsecondsSinceEpoch}';
    }
    setState(() => _sending = true);
    try {
      final thread = await repo.send(id: _threadId ?? widget.threadId, topic: widget.topic ?? 'other',
        text: body, requestId: _requestId!);
      if (!mounted) return;
      _requestId = null;
      if (_text.text.trim() == body) _text.clear();
      setState(() => _threadId = thread.id);
      ref.invalidate(supportThreadProvider(thread.id));
      ref.invalidate(supportThreadsProvider);
    } catch (error) {
      if (mounted) showAppSnack(context, failureMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _threadId ?? widget.threadId;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19.r,
              backgroundColor: AppColors.darkGreen,
              child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 20.r),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('অফিস সাপোর্ট', style: AppText.bodyStrong),
                  Text('সকাল ১০টা–সন্ধ্যা ৬টা', style: AppText.small),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: id == null
                ? _ChatBody(topic: widget.topic ?? 'other', topicLabel: widget.topicLabel ?? 'সাপোর্ট', thread: null)
                : AsyncValueView<SupportThread>(
                    value: ref.watch(supportThreadProvider(id)),
                    onRetry: () => ref.invalidate(supportThreadProvider(id)),
                    data: (t) => _ChatBody(topic: t.topic, topicLabel: t.topicLabel, thread: t),
                  ),
          ),
          _Composer(controller: _text, quick: id == null ? const [] : _quick, onQuick: _send, onSend: _send),
        ],
      ),
    );
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody({required this.topic, required this.topicLabel, required this.thread});

  final String topic;
  final String topicLabel;
  final SupportThread? thread;

  @override
  Widget build(BuildContext context) {
    final t = thread;
    final messages = t?.messages ?? const <SupportMessage>[];
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(supportTopicIcon(topic), size: 15.r, color: AppColors.successText),
              SizedBox(width: 6.w),
              Text('বিষয়: $topicLabel', style: AppText.small.copyWith(color: AppColors.successText, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        SizedBox(height: 10.h),
        if (t == null)
          Padding(
            padding: EdgeInsets.only(top: 24.h),
            child: Text(
              'সমস্যাটা নিচে লিখুন — কোন পণ্য, কত টাকা, কখন — যত পরিষ্কার লিখবেন তত দ্রুত সমাধান হবে।',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ),
        for (var i = 0; i < messages.length; i++) ...[
          if (i == 0 || !_sameDay(messages[i - 1].at, messages[i].at))
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Center(child: Text(BnFormat.dateFull(messages[i].at), style: AppText.small)),
            ),
          _Bubble(message: messages[i], showAuthor: messages[i].fromOffice && (i == 0 || !messages[i - 1].fromOffice)),
        ],
        if (t != null && t.resolved) ...[
          SizedBox(height: 8.h),
          const InfoBanner(
            icon: Icons.check_circle_outline_rounded,
            text: 'অফিস এটিকে "সমাধান হয়েছে" হিসেবে বন্ধ করেছে। আবার লিখলে কথোপকথন খুলে যাবে।',
          ),
        ],
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.showAuthor});

  final SupportMessage message;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final mine = !message.fromOffice;
    final r = Radius.circular(16.r);
    final tail = Radius.circular(4.r);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 0.8.sw),
        child: Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (showAuthor)
                Padding(
                  padding: EdgeInsets.only(left: 4.w, bottom: 3.h),
                  child: Text('অফিস · ${message.author}', style: AppText.small),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: mine ? AppColors.primary : Colors.white,
                  border: mine ? null : Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.only(topLeft: r, topRight: r, bottomLeft: mine ? r : tail, bottomRight: mine ? tail : r),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  child: Text(message.text, style: AppText.body.copyWith(color: mine ? Colors.white : AppColors.textPrimary)),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 0),
                child: Text(BnFormat.time(message.at), style: AppText.small),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.quick, required this.onQuick, required this.onSend});

  final TextEditingController controller;
  final List<String> quick;
  final ValueChanged<String> onQuick;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (quick.isNotEmpty) ...[
                SizedBox(
                  height: 40.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: quick.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (_, i) => ActionChip(
                      label: Text(quick[i], style: AppText.caption.copyWith(color: AppColors.textPrimary)),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.inputBorder),
                      shape: const StadiumBorder(),
                      onPressed: () => onQuick(quick[i]),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      keyboardType: TextInputType.multiline,
                      style: AppText.body,
                      decoration: InputDecoration(
                        hintText: 'সমস্যাটা লিখুন…',
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22.r)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22.r),
                          borderSide: const BorderSide(color: AppColors.inputBorder),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Semantics(
                    button: true,
                    label: 'পাঠান',
                    child: Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onSend,
                        child: SizedBox.square(dimension: 48.r, child: Icon(Icons.send_rounded, color: Colors.white, size: 21.r)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
