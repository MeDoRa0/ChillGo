import 'package:equatable/equatable.dart';
import '../../../domain/repositories/auth_repository.dart';

class AuthState extends Equatable {
  final AuthStatus status;
  final UserCredentials? credentials;

  const AuthState._({this.status = AuthStatus.unknown, this.credentials});

  const AuthState.unknown() : this._();

  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  const AuthState.authenticatedNoProfile(UserCredentials credentials)
    : this._(
        status: AuthStatus.authenticatedNoProfile,
        credentials: credentials,
      );

  const AuthState.authenticatedWithProfile(UserCredentials credentials)
    : this._(
        status: AuthStatus.authenticatedWithProfile,
        credentials: credentials,
      );

  @override
  List<Object?> get props => [status, credentials];
}
