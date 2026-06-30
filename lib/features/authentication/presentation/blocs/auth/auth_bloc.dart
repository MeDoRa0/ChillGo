import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    
    _statusSubscription = _authRepository.status.listen(
      (status) => add(AuthStatusChanged(status)),
    );
  }

  void _onStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) {
    switch (event.status) {
      case AuthStatus.unauthenticated:
        emit(const AuthState.unauthenticated());
        break;
      case AuthStatus.authenticatedNoProfile:
        final creds = _authRepository.currentCredentials;
        if (creds != null) {
          emit(AuthState.authenticatedNoProfile(creds));
        } else {
          emit(const AuthState.unauthenticated());
        }
        break;
      case AuthStatus.authenticatedWithProfile:
        final creds = _authRepository.currentCredentials;
        if (creds != null) {
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

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.signOut();
  }

  @override
  Future<void> close() {
    _statusSubscription.cancel();
    return super.close();
  }
}
