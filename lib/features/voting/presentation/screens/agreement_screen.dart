import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/widgets/responsive_content.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../core/presentation/widgets/sunshine_background.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';
import '../../../outings/domain/entities/outing_status.dart';
import '../../../outings/domain/repositories/outing_repository.dart';
import '../../domain/entities/agreement_category.dart';
import '../../domain/entities/agreement_command.dart';
import '../../domain/repositories/agreement_repository.dart';
import '../cubit/agreement_command/agreement_command_cubit.dart';
import '../cubit/agreement_detail/agreement_detail_cubit.dart';
import '../widgets/attendance_summary.dart';
import '../widgets/confirmed_result_summary.dart';
import '../widgets/proposal_ballot.dart';

part '../widgets/agreement_screen/agreement_body.dart';
part '../widgets/agreement_screen/organizer_controls.dart';
part '../widgets/agreement_screen/reopen_control.dart';

class AgreementScreen extends StatelessWidget {
  const AgreementScreen({super.key, required this.outingId});
  final String outingId;
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => sl<AgreementDetailCubit>()..watch(outingId)),
      BlocProvider(create: (_) => sl<AgreementCommandCubit>()),
    ],
    child: _AgreementBody(outingId: outingId),
  );
}
