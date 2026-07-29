import 'dart:io';

/// Runs the reproducible, automated release gates and fails on the first gate.
/// Integration tests are opt-in because they require an approved device/emulator.
Future<void> main(List<String> arguments) async {
  final runAndroidIntegration = arguments.contains('--android-integration');
  final runBuilds = arguments.contains('--build-packages');
  final artifactDir = Directory('build/release-validation')
    ..createSync(recursive: true);
  final commands = <_Command>[
    const _Command('flutter', ['analyze']),
    const _Command('flutter', ['test']),
    const _Command('npm', ['test'], workingDirectory: 'functions'),
    const _Command('npm', ['test'], workingDirectory: 'firestore_tests'),
    if (runAndroidIntegration) ...[
      const _Command('flutter', [
        'test',
        'integration_test/mvp_android_e2e_test.dart',
      ]),
      const _Command('flutter', [
        'test',
        'integration_test/release_performance_test.dart',
      ]),
    ],
    if (runBuilds) ...[
      const _Command('flutter', ['build', 'appbundle', '--release']),
      const _Command('flutter', ['build', 'ipa', '--release', '--no-codesign']),
    ],
  ];

  for (final attempt in [1, 2]) {
    for (final command in commands) {
      final name = '$attempt-${command.label.replaceAll(' ', '_')}';
      final result = await Process.run(
        command.executable,
        command.arguments,
        workingDirectory: command.workingDirectory,
      );
      File(
        '${artifactDir.path}/$name.log',
      ).writeAsStringSync('${result.stdout}${result.stderr}');
      if (result.exitCode != 0) {
        stderr.writeln(
          'Release gate failed: ${command.label} (attempt $attempt).',
        );
        exitCode = result.exitCode;
        return;
      }
    }
  }
}

class _Command {
  const _Command(this.executable, this.arguments, {this.workingDirectory});
  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
  String get label => '$executable ${arguments.join(' ')}';
}
