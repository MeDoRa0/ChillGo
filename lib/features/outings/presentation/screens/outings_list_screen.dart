import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/widgets/app_back_button.dart';
import '../../../voting/domain/repositories/agreement_repository.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';
import '../../domain/entities/outing.dart';
import '../../domain/repositories/outing_repository.dart';
import '../cubit/outings_list/outings_list_cubit.dart';
import '../widgets/interactive_outing_card.dart';

class OutingsListScreen extends StatelessWidget {
  final String crewId;

  const OutingsListScreen({super.key, required this.crewId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OutingsListCubit(outingRepository: sl<OutingRepository>())
            ..load(crewId),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F1A),
          leading: AppBackButton(fallbackRoute: '/crews/$crewId'),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Outings', style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              tooltip: 'Create outing',
              onPressed: () => context.go('/crews/$crewId/outings/new'),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: BlocBuilder<OutingsListCubit, OutingsListState>(
          builder: (context, state) {
            if (state is OutingsListLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OutingsListError) {
              return _Message(state.message);
            }
            final outings = state is OutingsListLoaded
                ? state.outings
                : const <Outing>[];
            if (outings.isEmpty) {
              return const _Message('No outings yet.');
            }
            final active = outings.where(
              (outing) => !outing.status.isHistorical,
            );
            final history = outings.where(
              (outing) => outing.status.isHistorical,
            );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(title: 'Active', outings: active.toList()),
                const SizedBox(height: 20),
                _Section(title: 'History', outings: history.toList()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Outing> outings;

  const _Section({required this.title, required this.outings});

  @override
  Widget build(BuildContext context) {
    if (outings.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        for (final outing in outings)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InteractiveOutingCard(
              outing: outing,
              outingRepository: sl<OutingRepository>(),
              currentUserId: sl<AuthRepository>().currentCredentials?.uid,
              agreementRepository: sl.isRegistered<AgreementRepository>()
                  ? sl<AgreementRepository>()
                  : null,
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String message;

  const _Message(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
