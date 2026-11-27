import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/bn_format.dart';
import '../../core/widgets/ui.dart';
import '../../data/support/support_repository.dart';
import 'support_home_screen.dart';

/// Chat with the office. Opened either for an existing conversation
/// ([threadId]) or to ask a new question on a [topic] — the first message then
/// creates the conversation.
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
  final _scroll = ScrollController();
  SupportThread? _thread;
  String? _error;
  bool _loading = false;
  bool _sending = false;
  String _requestId = SupportRepository.newRequestId();
  bool _refreshAfterSend = false;
  int _loadVersion = 0;

  SupportRepository get _repo => ref.read(supportRepositoryProvider);

  @override
  void initState() {
    super.initState();
    if (widget.threadId != null) {
      _loading = true;
      _load();
    }

  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    final id = _thread?.id ?? widget.threadId;
    if (id == null) return;
    final version = ++_loadVersion;
    try {
      final t = await _repo.open(id);
      if (!mounted || version != _loadVersion) return;
      final grew = t.messages.length != (_thread?.messages.length ?? 0);
      setState(() {
        _thread = t;
        _error = null;
        _loading = false;
      });
      if (grew) _toBottom();
    } on ApiException catch (e) {
      if (!mounted || (quiet && !_loading) || version != _loadVersion) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final body = (preset ?? _text.text).trim();
    if (body.isEmpty || _sending) return;
    _loadVersion++;
    setState(() => _sending = true);
    try {
      final current = _thread;
      final t = current == null
          ? await _repo.start(widget.topic ?? 'other', body, _requestId)
          : await _repo.send(current.id, body, _requestId);
      if (!mounted) return;
      if (preset == null) _text.clear();
      _requestId = SupportRepository.newRequestId();
      setState(() => _thread = t);
      ref.invalidate(supportThreadsProvider);
      _toBottom();
    } on ApiException catch (e) {
      // Text stays in the box; the same request id is reused on retry, so it is never stored twice.
      if (mounted) showDemoNotice(context, e.message);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        if (_refreshAfterSend) {
          _refreshAfterSend = false;
          unawaited(_load(quiet: true));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(supportUpdatesProvider, (_, next) {
      if (!next.hasValue) return;
      if (_sending) {
        _refreshAfterSend = true;
      } else {
        unawaited(_load(quiet: true));
      }
    });
    final t = _thread;
    final topic = t?.topic ?? widget.topic ?? 'other';
    final topicLabel = t?.topicLabel ?? widget.topicLabel ?? 'সাপোর্ট';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _Header(onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.support)),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null && t == null
                        ? _ErrorState(message: _error!, onRetry: () {
                            setState(() => _loading = true);
                            _load();
                          })
                        : ListView(
                            controller: _scroll,
                            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
                            children: [
                              Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                                  decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(999)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(supportTopicIcon(topic), size: 15.r, color: AppColors.primaryDark),
                                      SizedBox(width: 6.w),
                                      Text('বিষয়: $topicLabel',
                                          style: AppText.small.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              if (t == null)
                                Padding(
                                  padding: EdgeInsets.only(top: 24.h),
                                  child: Text(
                                    'আপনার প্রশ্নটি নিচে লিখুন। যত বিস্তারিত লিখবেন, তত দ্রুত সঠিক উত্তর দেওয়া যাবে।',
                                    textAlign: TextAlign.center,
                                    style: AppText.caption,
                                  ),
                                )
                              else
                                ..._bubbles(t.messages),
                              if (t != null && t.resolved)
                                Padding(
                                  padding: EdgeInsets.only(top: 12.h),
                                  child: const InfoBox(
                                    tone: InfoTone.plain,
                                    icon: Icons.check_circle_outline_rounded,
                                    text: 'অফিস এটিকে "সমাধান হয়েছে" হিসেবে বন্ধ করেছে। আবার কিছু লিখলে কথোপকথন খুলে যাবে।',
                                  ),
                                ),
                            ],
                          ),
              ),
              _Composer(
                controller: _text,
                sending: _sending,
                quick: t == null ? const [] : _quick,
                onQuick: _send,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _bubbles(List<SupportMessage> messages) {
    final out = <Widget>[];
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final newDay = i == 0 || !_sameDay(messages[i - 1].at, m.at);
      if (newDay) {
        out.add(Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Center(child: Text(BnFormat.dateFull(m.at), style: AppText.small)),
        ));
      }
      final showAuthor = m.fromOffice && (i == 0 || !messages[i - 1].fromOffice);
      out.add(_Bubble(message: m, showAuthor: showAuthor));
    }
    return out;
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 16.w, 10.h),
        child: Row(
          children: [
            CircleIconButton(icon: Icons.arrow_back_rounded, label: 'পেছনে যান', size: 44, light: false, iconColor: AppColors.primary, onTap: onBack),
            SizedBox(width: 10.w),
            Container(
              width: 42.r,
              height: 42.r,
              decoration: const BoxDecoration(gradient: AppColors.headerGradient, shape: BoxShape.circle),
              child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 22.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('স্ট্রিট সেলস সাপোর্ট', style: AppText.cardTitle),
                  Text('অফিস সময়: সকাল ১০টা–সন্ধ্যা ৬টা', style: AppText.small),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.showAuthor});

  final SupportMessage message;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final mine = !message.fromOffice;
    final r = Radius.circular(18.r);
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
                  borderRadius: BorderRadius.only(topLeft: r, topRight: r, bottomLeft: mine ? r : tail, bottomRight: mine ? tail : r),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  child: SelectableText(
                    message.text,
                    style: AppText.body.copyWith(color: mine ? Colors.white : AppColors.textPrimary, height: 1.5),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 0),
                child: Text(BnFormat.time(message.at), style: AppText.small.copyWith(fontSize: 11.5.sp)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.sending, required this.quick, required this.onQuick, required this.onSend});

  final TextEditingController controller;
  final bool sending;
  final List<String> quick;
  final ValueChanged<String> onQuick;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quick.isNotEmpty)
              SizedBox(
                height: 40.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: quick.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (_, i) => ActionChip(
                    label: Text(quick[i], style: AppText.bodySmall.copyWith(fontSize: 13.sp)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.borderStrong),
                    shape: const StadiumBorder(),
                    onPressed: sending ? null : () => onQuick(quick[i]),
                  ),
                ),
              ),
            if (quick.isNotEmpty) SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 2000,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    style: AppText.body.copyWith(height: 1.4),
                    decoration: InputDecoration(
                      hintText: 'আপনার প্রশ্ন লিখুন…',
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22.r)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22.r),
                        borderSide: const BorderSide(color: AppColors.borderStrong),
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
                      onTap: sending ? null : onSend,
                      child: SizedBox.square(
                        dimension: 46.r,
                        child: sending
                            ? Padding(
                                padding: EdgeInsets.all(13.r),
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(Icons.send_rounded, color: Colors.white, size: 21.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44.r, color: AppColors.textSecondary),
            SizedBox(height: 10.h),
            Text(message, textAlign: TextAlign.center, style: AppText.body),
            SizedBox(height: 14.h),
            FilledButton(onPressed: onRetry, child: const Text('আবার চেষ্টা করুন')),
          ],
        ),
      ),
    );
  }
}
