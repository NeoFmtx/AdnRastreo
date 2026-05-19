import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/bootstrap/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await AppServices.init();

  if (AppServices.instance.trackingEnabled) {
    await AppServices.instance.orchestrator.start();
  }

  runApp(const OnecoreGpsApp());
}
