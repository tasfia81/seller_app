import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Size helpers on top of ScreenUtil. Touch targets never drop below 48dp.
abstract final class AppSize {
  static double get page => 16.w;
  static double get radius => 14.r;
  static double get radiusSm => 12.r;
  static double get button => 52.h.clamp(48.0, 60.0).toDouble();
  static double get touch => 48.h.clamp(48.0, 56.0).toDouble();
}
