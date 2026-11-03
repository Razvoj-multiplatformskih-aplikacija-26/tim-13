import 'package:bloc/bloc.dart';

final class ConsoleBlocObserver extends BlocObserver {
  const ConsoleBlocObserver(this.log);

  final void Function(String line) log;

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    log('${bloc.runtimeType} · created');
  }

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);
    log('${bloc.runtimeType} · ${transition.event.runtimeType} → ${transition.nextState}');
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    log('${bloc.runtimeType} · closed');
  }
}
