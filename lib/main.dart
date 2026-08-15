import 'dart:async';
import 'dart:ui';

import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/app/app.dart';
import 'package:olcerim/core/logging/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterCryptography.enable();
  FlutterError.onError = (details) { FlutterError.presentError(details); AppLogger.error('Flutter framework error', details.exception, details.stack); };
  PlatformDispatcher.instance.onError = (error, stack) { AppLogger.error('Unhandled platform error', error, stack); return true; };
  runZonedGuarded(() => runApp(const ProviderScope(child: OlcerimApp())), (error, stack) => AppLogger.error('Unhandled zone error', error, stack));
}
