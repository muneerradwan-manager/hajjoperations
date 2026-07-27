import 'package:bloc/bloc.dart';

import 'app_logger.dart';

/// Prints what every cubit in the app is doing.
///
/// [onError] is the one that earns its keep: a cubit that catches its own
/// failure and emits an error state swallows the stack trace with it, and this
/// is where the trace still comes out.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  static const _tag = 'bloc';

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (!AppLogger.enabled) return;
    // The type only. A whole state object is a screenful — the states of this
    // app carry entire employee lists — and what is wanted here is the shape of
    // the sequence, not its contents.
    AppLogger.debug(
      _tag,
      '${bloc.runtimeType}: '
      '${change.currentState.runtimeType} → ${change.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.error(_tag, '${bloc.runtimeType} threw', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    AppLogger.debug(_tag, '${bloc.runtimeType} created');
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    AppLogger.debug(_tag, '${bloc.runtimeType} closed');
    super.onClose(bloc);
  }
}
