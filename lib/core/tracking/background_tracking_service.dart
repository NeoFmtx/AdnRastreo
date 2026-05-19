import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../log/deep_log.dart';

/// Permisos, notificación persistente (Android) y wake lock.
class BackgroundTrackingService {
  BackgroundTrackingService._();
  static final BackgroundTrackingService instance =
      BackgroundTrackingService._();

  final _log = DeepLog.instance;

  Future<bool> requestPermissions() async {
    var loc = await Geolocator.checkPermission();
    if (loc == LocationPermission.denied) {
      loc = await Geolocator.requestPermission();
    }
    if (loc == LocationPermission.deniedForever) {
      return false;
    }

    if (Platform.isAndroid) {
      final always = await Permission.locationAlways.request();
      if (!always.isGranted) {
        _log.w(
          'Concede ubicación "Permitir todo el tiempo" para rastreo con pantalla apagada',
        );
      }
      await Permission.notification.request();
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }

    loc = await Geolocator.checkPermission();
    return loc == LocationPermission.always ||
        loc == LocationPermission.whileInUse;
  }

  LocationSettings locationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'AdnRastreo activo',
          notificationText: 'Rastreo GPS en segundo plano',
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );
  }

  Future<bool> start() async {
    final ok = await requestPermissions();
    if (!ok) {
      _log.e('Permisos de ubicación denegados');
      return false;
    }
    await WakelockPlus.enable();
    _log.i('Servicio GPS en primer plano activo');
    return true;
  }

  Future<void> stop() async {
    await WakelockPlus.disable();
    _log.i('Servicio GPS detenido');
  }
}
