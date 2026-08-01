import 'package:flutter/material.dart';
import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/widgets/app_back_button.dart';
import '../../../../core/presentation/widgets/responsive_content.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../core/presentation/widgets/sunshine_background.dart';
import '../../../voting/domain/repositories/agreement_repository.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';
import '../../domain/entities/outing.dart';
import '../../domain/repositories/outing_repository.dart';
import '../cubit/outings_list/outings_list_cubit.dart';
import '../widgets/interactive_outing_card.dart';

part '../widgets/outings_list_screen/section.dart';
part '../widgets/outings_list_screen/message.dart';

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
        appBar: AppBar(
          leading: AppBackButton(fallbackRoute: '/crews/$crewId'),
          title: const Text('Outings'),
          actions: [
            IconButton(
              tooltip: 'Create outing',
              onPressed: () => context.go('/crews/$crewId/outings/new'),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: SunshineBackground(
          child: ResponsiveContent(
            maxWidth: 900,
            child: BlocBuilder<OutingsListCubit, OutingsListState>(
              builder: (context, state) {
                if (state is OutingsListLoading) {
                  return const ShimmerListPlaceholder(itemCount: 3);
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
        ),
      ),
    );
  }
}
