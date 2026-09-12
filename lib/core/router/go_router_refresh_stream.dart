import 'dart:async';

import 'package:flutter/foundation.dart';

/// Turns any stream into a `Listenable`, so `go_router`'s
/// `refreshListenable` can re-evaluate redirects whenever the stream
/// emits — used here with `AuthSessionBloc.stream`, but generic enough
/// for any future Bloc/Cubit to drive router redirects the same way.
class GoRouterRefreshStream extends ChangeNotifier {
  /// Creates a [GoRouterRefreshStream] wrapping the given stream.
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
