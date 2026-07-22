import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/agreement_repository.dart';

sealed class AgreementDetailState {
  const AgreementDetailState();
}

class AgreementDetailInitial extends AgreementDetailState {
  const AgreementDetailInitial();
}

class AgreementDetailLoading extends AgreementDetailState {
  const AgreementDetailLoading();
}

class AgreementDetailLoaded extends AgreementDetailState {
  const AgreementDetailLoaded(this.detail);
  final AgreementDetail detail;
}

class AgreementDetailFailure extends AgreementDetailState {
  const AgreementDetailFailure(this.message);
  final String message;
}

class AgreementDetailCubit extends Cubit<AgreementDetailState> {
  AgreementDetailCubit({required this.repository})
    : super(const AgreementDetailInitial());
  final AgreementRepository repository;
  StreamSubscription? _subscription;
  void watch(String outingId) {
    emit(const AgreementDetailLoading());
    _subscription?.cancel();
    _subscription = repository
        .streamAgreement(outingId)
        .listen(
          (detail) => detail == null
              ? emit(const AgreementDetailFailure('Agreement not found.'))
              : emit(AgreementDetailLoaded(detail)),
          onError: (Object e) => emit(AgreementDetailFailure(e.toString())),
        );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
