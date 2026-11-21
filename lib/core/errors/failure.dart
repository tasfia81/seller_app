/// Typed failures that repositories throw. UI maps them to Bangla messages.
sealed class Failure implements Exception {
  const Failure();

  String get message;
}

class NetworkFailure extends Failure {
  const NetworkFailure();
  @override
  String get message => 'ইন্টারনেট সংযোগ নেই। সংযোগ ঠিক করে আবার চেষ্টা করুন।';
}

class NotConnectedFailure extends Failure {
  const NotConnectedFailure();
  @override
  String get message => 'সার্ভারের সাথে সংযোগ এখনো চালু হয়নি।';
}

class PermissionFailure extends Failure {
  const PermissionFailure();
  @override
  String get message => 'এই কাজের অনুমতি আপনার নেই।';
}

class ValidationFailure extends Failure {
  const ValidationFailure(this.message);
  @override
  final String message;
}

class InsufficientStockFailure extends Failure {
  const InsufficientStockFailure(this.available);
  final String available;
  @override
  String get message => 'পর্যাপ্ত স্টক নেই। হাতে আছে $available।';
}

class UnknownFailure extends Failure {
  const UnknownFailure();
  @override
  String get message => 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।';
}

String failureMessage(Object error) =>
    error is Failure ? error.message : const UnknownFailure().message;
