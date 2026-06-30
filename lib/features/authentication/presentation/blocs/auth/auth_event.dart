import 'package:equatable/equatable.dart';
import '../../../domain/repositories/auth_repository.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStatusChanged extends AuthEvent {
  final AuthStatus status;

  const AuthStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class AuthLogoutRequested extends AuthEvent {}
