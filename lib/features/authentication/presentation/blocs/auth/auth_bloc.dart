import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late final StreamSubscription<AuthStatus> _statusSubscription;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState.unknown()) {
    on<AuthStatusChanged>(_onStatusChanged);
    on<AuthLogoutRequested>(_onLogoutRequested);

    if (kDebugMode) {
      debugPrint('[AuthBloc] subscribing to auth status stream');
    }
    _statusSubscription = _authRepository.status.listen((status) {
      if (kDebugMode) {
        debugPrint('[AuthBloc] status stream emitted: $status');
      }
      add(AuthStatusChanged(status));
    });

    final currentStatus = _authRepository.currentStatus;
    if (kDebugMode) {
      debugPrint('[AuthBloc] dispatching currentStatus: $currentStatus');
    }
    add(AuthStatusChanged(currentStatus));
  }

  void _onStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) {
    if (kDebugMode) {
      debugPrint('[AuthBloc] AuthStatusChanged received: ${event.status}');
    }
    switch (event.status) {
      case AuthStatus.unauthenticated:
        emit(const AuthState.unauthenticated());
        break;
      case AuthStatus.authenticatedNoProfile:
        final creds = _authRepository.currentCredentials;
        if (creds != null) {
          if (kDebugMode) {
            debugPrint(
              '[AuthBloc] Emitting authenticatedNoProfile with uid: ${creds.uid}',
            );
          }
          emit(AuthState.authenticatedNoProfile(creds));
        } else {
          emit(const AuthState.unauthenticated());
        }
        break;
      case AuthStatus.authenticatedWithProfile:
        final creds = _authRepository.currentCredentials;
        if (creds != null) {
          if (kDebugMode) {
            debugPrint(
              '[AuthBloc] Emitting authenticatedWithProfile with uid: ${creds.uid}, username: ${creds.username}',
            );
          }
          emit(AuthState.authenticatedWithProfile(creds));
        } else {
          emit(const AuthState.unauthenticated());
        }
        break;
      case AuthStatus.unknown:
      default:
        emit(const AuthState.unknown());
        break;
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
  }

  @override
  Future<void> close() {
    _statusSubscription.cancel();
    return super.close();
  }
}
