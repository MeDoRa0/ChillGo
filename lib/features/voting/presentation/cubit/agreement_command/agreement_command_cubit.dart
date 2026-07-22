import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/agreement_command.dart';
import '../../../domain/repositories/agreement_repository.dart';

sealed class AgreementCommandState {
  const AgreementCommandState();
}

class AgreementCommandIdle extends AgreementCommandState {
  const AgreementCommandIdle();
}

class AgreementCommandPending extends AgreementCommandState {
  const AgreementCommandPending(this.id);
  final String id;
}

class AgreementCommandSucceeded extends AgreementCommandState {
  const AgreementCommandSucceeded(this.command);
  final AgreementCommand command;
}

class AgreementCommandFailed extends AgreementCommandState {
  const AgreementCommandFailed(this.code, this.message);
  final String? code;
  final String message;
}

class AgreementCommandCubit extends Cubit<AgreementCommandState> {
  AgreementCommandCubit({required this.repository})
    : super(const AgreementCommandIdle());
  final AgreementRepository repository;
  StreamSubscription? _sub;
  Future<void> run(Future<String> Function() action) async {
    try {
      final id = await action();
      emit(AgreementCommandPending(id));
      await _sub?.cancel();
      _sub = repository.streamCommand(id).listen((c) {
        if (c?.status == AgreementCommandStatus.succeeded) {
          emit(AgreementCommandSucceeded(c!));
        } else if (c?.status == AgreementCommandStatus.failed) {
          emit(
            AgreementCommandFailed(
              c?.errorCode,
              c?.errorMessage ?? 'Command failed.',
            ),
          );
        }
      });
    } catch (e) {
      emit(AgreementCommandFailed(null, e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
