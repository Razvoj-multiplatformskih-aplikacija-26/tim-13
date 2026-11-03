import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'dependencies.dart';

void main() {
  if (kDebugMode) Bloc.observer = ConsoleBlocObserver(debugPrint);
  runApp(AgroFlowApp(dependencies: AppDependencies.fake()));
}
