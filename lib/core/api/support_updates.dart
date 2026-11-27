import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/app_config.dart';
import 'api_client.dart';

/// Reconnects with a new one-use ticket. A ready frame also refreshes data
/// missed while the socket was offline.
Stream<int> supportUpdates(ApiClient api) {
  WebSocketChannel? socket;
  Timer? retry;
  Timer? heartbeat;
  var stopped = false;
  var sequence = 0;
  var retrySeconds = 1;
  late final StreamController<int> controller;

  void schedule(Future<void> Function() connect) {
    if (stopped || retry?.isActive == true) return;
    retry = Timer(Duration(seconds: retrySeconds), connect);
    retrySeconds = (retrySeconds * 2).clamp(1, 15);
  }

  Future<void> connect() async {
    final WebSocketChannel channel;
    try {
      final result = await api.post('/support/live-ticket') as Map;
      if (stopped) return;
      final apiUri = Uri.parse(AppConfig.apiBaseUrl);
      final uri = apiUri.replace(
        scheme: apiUri.scheme == 'https' ? 'wss' : 'ws',
        path: '${apiUri.path.replaceFirst(RegExp(r'/$'), '')}/support/live',
      );
      channel = WebSocketChannel.connect(uri);
      socket = channel;
      await channel.ready.timeout(const Duration(seconds: 8));
      if (stopped) return;
      channel.sink.add(result['ticket'] as String);
    } catch (_) {
      final failed = socket;
      socket = null;
      if (failed != null) unawaited(failed.sink.close());
      schedule(connect);
      return;
    }

    void disconnected() {
      if (socket != channel) return;
      socket = null;
      heartbeat?.cancel();
      unawaited(channel.sink.close());
      schedule(connect);
    }

    void resetHeartbeat() {
      heartbeat?.cancel();
      heartbeat = Timer(const Duration(seconds: 35), disconnected);
    }

    resetHeartbeat();
    channel.stream.listen((frame) {
      if (socket != channel || stopped) return;
      resetHeartbeat();
      if (frame == 'ready' || frame == 'changed') {
        retrySeconds = 1;
        controller.add(++sequence);
      }
    }, onDone: disconnected, onError: (Object _) => disconnected(), cancelOnError: true);
  }

  controller = StreamController<int>(
    onListen: () => unawaited(connect()),
    onCancel: () {
      stopped = true;
      retry?.cancel();
      heartbeat?.cancel();
      final active = socket;
      socket = null;
      if (active != null) unawaited(active.sink.close());
    },
  );
  return controller.stream;
}
