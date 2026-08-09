import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/gts_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // A parent-facing tracking screen is a one-handed, portrait experience.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: GtsApp()));
}
