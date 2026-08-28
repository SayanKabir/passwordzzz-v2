import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

/// Logs every bloc transition and error in one place.
///
/// Deliberately never logs state *contents* — an `Unlocked` state carries the
/// vault key and a `VaultLoaded` state carries decrypted entries. Only the
/// runtime type of each state is recorded.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    developer.log(
      '${transition.currentState.runtimeType} '
      '--${transition.event.runtimeType}--> '
      '${transition.nextState.runtimeType}',
      name: bloc.runtimeType.toString(),
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    developer.log(
      'unhandled error',
      name: bloc.runtimeType.toString(),
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
