import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class ProductInfraService {
  ProductInfraService._();

  static final analytics = FirebaseAnalytics.instance;
  static final remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> init() async {
    await _initCrashlytics();
    await _initRemoteConfig();
    await analytics.logAppOpen();
  }

  static Future<void> identifyUser(String? userId) async {
    await analytics.setUserId(id: userId);
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
    }
  }

  static Future<void> track(String name, {Map<String, Object>? parameters}) {
    return analytics.logEvent(name: name, parameters: parameters);
  }

  static Future<void> recordError(Object error, StackTrace stack) async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  }

  static Future<void> _initCrashlytics() async {
    if (kIsWeb) return;

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      kReleaseMode,
    );
  }

  static Future<void> _initRemoteConfig() async {
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kReleaseMode
            ? const Duration(hours: 1)
            : const Duration(minutes: 1),
      ),
    );
    await remoteConfig.setDefaults(const {
      'require_email_verification': true,
      'enable_graphical_criteria': true,
      'maintenance_mode': false,
    });
    unawaited(remoteConfig.fetchAndActivate());
  }
}
