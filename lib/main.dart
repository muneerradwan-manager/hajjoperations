import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap.dart';

Future<void> main() async {
  final deps = await bootstrap();
  runApp(HajjOperationsApp(deps: deps));
}
