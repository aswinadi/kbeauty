import 'package:flutter/material.dart';

class Responsive {
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}
