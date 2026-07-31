import 'package:chillgo/core/di/injection_container.dart';
import 'package:chillgo/core/presentation/widgets/app_back_button.dart';
import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';
import 'package:chillgo/features/outings/domain/repositories/outing_repository.dart';
import 'package:chillgo/features/outings/presentation/widgets/interactive_outing_card.dart';
import 'package:chillgo/features/voting/domain/repositories/agreement_repository.dart';
import 'package:flutter/material.dart';
import 'package:chillgo/core/presentation/theme/chillgo_colors.dart';
import 'package:chillgo/core/presentation/widgets/responsive_content.dart';
import 'package:chillgo/core/presentation/widgets/sunshine_background.dart';

class OutingReviewScreen extends StatelessWidget {
  const OutingReviewScreen({super.key, required this.outingId});

  final String outingId;

  @override
  Widget build(BuildContext context) {
    final outingRepository = sl<OutingRepository>();
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Review outing'),
      ),
      body: SunshineBackground(
        child: ResponsiveContent(
          maxWidth: 900,
          child: StreamBuilder<OutingDetail?>(
            stream: outingRepository.streamOutingDetail(outingId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _ReviewMessage('Could not load this outing.');
              }
              final detail = snapshot.data;
              if (detail == null) {
                return const Center(
                  child: CircularProgressIndicator(color: ChillGoColors.coral),
                );
              }
              return OutingReviewCard(
                outing: detail.outing,
                participants: detail.participants,
                outingRepository: outingRepository,
                agreementRepository: sl.isRegistered<AgreementRepository>()
                    ? sl<AgreementRepository>()
                    : null,
                currentUserId: sl<AuthRepository>().currentCredentials?.uid,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReviewMessage extends StatelessWidget {
  const _ReviewMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: ChillGoColors.inkMuted),
      ),
    ),
  );
}
