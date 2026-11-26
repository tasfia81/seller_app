import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

class ApiStatus extends StatelessWidget {
  const ApiStatus(this.value, {super.key, required this.onRetry});

  final AsyncValue<Object?> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = value.error;
    if (error == null) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error is ApiException ? error.message : 'তথ্য লোড করা যায়নি।', textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('আবার চেষ্টা করুন')),
          ],
        ),
      ),
    );
  }
}
