import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chillgo/core/data/repositories/release_metadata_repository_impl.dart';

void main() {
  test('uses supplied build metadata without secrets', () {
    final repository = ReleaseMetadataRepositoryImpl(
      releaseVersion: '1.2.3+4',
      platform: TargetPlatform.android,
    );

    expect(repository.releaseVersion, '1.2.3+4');
    expect(repository.clientType, 'android');
    expect(
      repository.diagnosticsContext('network_failure').toSafeMap(),
      containsPair('failure_category', 'network_failure'),
    );
  });

  test('normalizes uncontrolled failure categories', () {
    final repository = ReleaseMetadataRepositoryImpl(
      platform: TargetPlatform.iOS,
    );

    expect(
      repository.diagnosticsContext('message: private text').failureCategory,
      'unexpected_failure',
    );
  });
}
