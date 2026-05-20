import 'package:flutter/material.dart';

abstract final class AppLayout {
  static const double screenPaddingH = 24;
  static const double screenPaddingTop = 16;
  static const double screenPaddingBottom = 24;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(
    screenPaddingH,
    screenPaddingTop,
    screenPaddingH,
    screenPaddingBottom,
  );

  static const EdgeInsets screenPaddingSymmetricH = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
  );

  static const double cardRadius = 16;
  static const double buttonRadius = 12;
  static const double inputRadius = 12;
  static const double whiteTopSheetRadius = 26;
}
