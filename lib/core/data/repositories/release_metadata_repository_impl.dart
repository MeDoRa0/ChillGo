import 'package:flutter/foundation.dart';

import '../../domain/entities/diagnostics_context.dart';
import '../../domain/repositories/release_metadata_repository.dart';

/// Build-time metadata only. It intentionally has no credentials or device IDs.
class ReleaseMetadataRepositoryImpl implements ReleaseMetadataRepository {
  ReleaseMetadataRepositoryImpl({
    String? releaseVersion,
    TargetPlatform? platform,
  }) : _releaseVersion =
           releaseVersion ??
           const String.fromEnvironment(
             'APP_RELEASE_VERSION',
             defaultValue: '0.1.0',
           ),
       _platform = platform;

  final String _releaseVersion;
  final TargetPlatform? _platform;

  @override
  String get releaseVersion => _releaseVersion;

  @override
  String get clientType {
    final platform = _platform ?? defaultTargetPlatform;
    return switch (platform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'unsupported',
    };
  }

  @override
  DiagnosticsContext diagnosticsContext(String failureCategory) {
    final category = RegExp(r'^[a-z_]{1,40}$').hasMatch(failureCategory)
        ? failureCategory
        : 'unexpected_failure';
    return DiagnosticsContext(
      releaseVersion: releaseVersion,
      clientType: clientType,
      failureCategory: category,
    );
  }
}
