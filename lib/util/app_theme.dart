// dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'util.dart';

/// rootstock.io's actual site background (`--bs-body-bg: #000`).
const rootstockBlack = Color(0xFF000000);

/// rootstock.io's actual site body text color (`--bs-body-color: #faf9f5`).
const rootstockCream = Color(0xFFFAF9F5);

/// App theme modeled on rootstock.io's own site: black background, cream
/// body text, and the brand accent colors already used throughout this app
/// (see [purple], [green], [lightBlue], [pink], [orange], [yellow] in
/// util.dart — those already match rootstock.io's palette exactly).
///
/// Typography uses Manrope (via google_fonts) as a free stand-in for
/// rootstock.io's proprietary "Rootstock Sans" webfont, which isn't licensed
/// for reuse in this separate, non-official app.
final ThemeData rootstockTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: rootstockBlack,
  primaryColor: purple(),
  colorScheme: ColorScheme.dark(
    primary: purple() ?? rootstockCream,
    secondary: lightBlue() ?? rootstockCream,
    surface: rootstockBlack,
    onSurface: rootstockCream,
    onPrimary: rootstockCream,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: rootstockBlack,
    foregroundColor: rootstockCream,
  ),
  textTheme: GoogleFonts.manropeTextTheme(ThemeData(brightness: Brightness.dark).textTheme).apply(
    bodyColor: rootstockCream,
    displayColor: rootstockCream,
  ),
);
