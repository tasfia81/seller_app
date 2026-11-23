import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Lets the update notice appear above any screen.
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Over-the-air updates (Shorebird code push).
///
/// On start and whenever the app comes back to the foreground (at most every
/// 30 minutes) it checks for a new patch and downloads it quietly. The patch
/// takes effect the next time the app is opened — a seller in the middle of a
/// sale is never interrupted; they only see a short notice.
///
/// In builds made with `flutter run` / `flutter build` (not `shorebird
/// release`) the updater is unavailable and this does nothing.
class AppUpdateWatcher extends StatefulWidget {
  const AppUpdateWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateWatcher> createState() => _AppUpdateWatcherState();
}

class _AppUpdateWatcherState extends State<AppUpdateWatcher> with WidgetsBindingObserver {
  static const _minGap = Duration(minutes: 30);

  final _updater = ShorebirdUpdater();
  DateTime? _lastCheck;
  bool _busy = false;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_busy || _notified || !_updater.isAvailable) return;
    final now = DateTime.now();
    if (_lastCheck != null && now.difference(_lastCheck!) < _minGap) return;
    _lastCheck = now;
    _busy = true;
    try {
      var status = await _updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        await _updater.update();
        status = UpdateStatus.restartRequired;
      }
      if (status == UpdateStatus.restartRequired) _notifyReady();
    } on UpdateException {
      // No network or download failed: try again on the next check.
    } catch (_) {
      // Never let an update problem disturb selling.
    } finally {
      _busy = false;
    }
  }

  void _notifyReady() {
    _notified = true;
    appMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 8),
        content: Text('অ্যাপের নতুন আপডেট নামানো হয়েছে। অ্যাপ বন্ধ করে আবার খুললে চালু হবে।'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
