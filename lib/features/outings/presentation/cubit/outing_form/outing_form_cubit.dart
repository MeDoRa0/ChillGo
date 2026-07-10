import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/outing.dart';
import '../../../domain/repositories/outing_repository.dart';

abstract class OutingFormState extends Equatable {
  const OutingFormState();

  @override
  List<Object?> get props => [];
}

class OutingFormInitial extends OutingFormState {
  const OutingFormInitial();
}

class OutingFormSubmitting extends OutingFormState {
  const OutingFormSubmitting();
}

class OutingFormSuccess extends OutingFormState {
  final String outingId;

  const OutingFormSuccess(this.outingId);

  @override
  List<Object?> get props => [outingId];
}

class OutingFormFailure extends OutingFormState {
  final String message;

  const OutingFormFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class OutingFormCubit extends Cubit<OutingFormState> {
  final OutingRepository outingRepository;

  OutingFormCubit({required this.outingRepository})
    : super(const OutingFormInitial());

  Future<void> createOuting({
    required String crewId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required String locationText,
  }) async {
    emit(const OutingFormSubmitting());
    try {
      final outingId = await outingRepository.createOuting(
        crewId: crewId,
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        locationText: locationText,
      );
      emit(OutingFormSuccess(outingId));
    } catch (error) {
      emit(OutingFormFailure(error.toString()));
    }
  }

  Future<void> updateOuting({
    required Outing outing,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required String locationText,
  }) async {
    emit(const OutingFormSubmitting());
    try {
      await outingRepository.updateOutingDetails(
        outingId: outing.id,
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        locationText: locationText,
      );
      emit(OutingFormSuccess(outing.id));
    } catch (error) {
      emit(OutingFormFailure(error.toString()));
    }
  }

  Future<void> cancelOuting({
    required String outingId,
    required String reason,
  }) async {
    emit(const OutingFormSubmitting());
    try {
      await outingRepository.cancelOuting(
        outingId: outingId,
        cancelledReason: reason,
      );
      emit(OutingFormSuccess(outingId));
    } catch (error) {
      emit(OutingFormFailure(error.toString()));
    }
  }
}
