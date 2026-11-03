import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'router.dart';

class AgroFlowApp extends StatefulWidget {
  const AgroFlowApp({super.key, required this.dependencies});

  static const locale = Locale.fromSubtags(languageCode: serbianLatinLanguage, scriptCode: serbianLatinScript);

  final AppDependencies dependencies;

  @override
  State<AgroFlowApp> createState() => _AgroFlowAppState();
}

class _AgroFlowAppState extends State<AgroFlowApp> {
  late final GoRouter _router = createRouter();
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  void _showNotice(BuildContext context, MyWorkOrdersNotice notice) {
    final message = switch (notice) {
      WorkOrderStarted() => 'Nalog je započet.',
      WorkOrderCancelled() => 'Nalog je otkazan.',
      WorkOrderActionRejected(:final error) => error.message,
      WorkOrderActionFailed() => 'Izmena nije sačuvana. Pokušajte ponovo.',
    };
    _messenger.currentState?.showSnackBar(SnackBar(content: Text(message)));
    context.read<MyWorkOrdersBloc>().add(const MyWorkOrdersNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return RepositoryProvider.value(
      value: dependencies,
      child: BlocProvider(
        create: (_) => MyWorkOrdersBloc(
          getWorkBook: dependencies.getWorkBook,
          startWorkOrder: dependencies.startWorkOrder,
          cancelWorkOrder: dependencies.cancelWorkOrder,
          worker: dependencies.worker,
        )..add(const MyWorkOrdersRequested()),
        child: BlocListener<MyWorkOrdersBloc, MyWorkOrdersState>(
          listenWhen: (previous, current) => current is MyWorkOrdersLoaded && current.notice != null,
          listener: (context, state) => _showNotice(context, (state as MyWorkOrdersLoaded).notice!),
          child: MaterialApp.router(
            title: 'AgroFlow',
            theme: AgroTheme.light(),
            scaffoldMessengerKey: _messenger,
            locale: AgroFlowApp.locale,
            supportedLocales: const [AgroFlowApp.locale],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
