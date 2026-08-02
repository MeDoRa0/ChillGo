import 'package:chillgo/features/profile/presentation/models/avatar_preset.dart';
import 'package:chillgo/features/profile/presentation/utils/image_helper.dart';
import 'package:chillgo/features/profile/presentation/widgets/avatar_source_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns the selected built-in avatar', (tester) async {
    AvatarChangeChoice? selectedChoice;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selectedChoice = await showAvatarSourceSheet(context);
            },
            child: const Text('Open avatar choices'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open avatar choices'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('avatar-preset-3')));
    await tester.pumpAndSettle();

    expect(selectedChoice, isA<PresetAvatarChoice>());
    expect((selectedChoice as PresetAvatarChoice).preset, avatarPresets[3]);
  });

  testWidgets('prepares a built-in avatar for upload', (tester) async {
    final selectedAvatar = await prepareAvatarChange(
      PresetAvatarChoice(avatarPresets.first),
      ImageHelper(),
    );

    expect(selectedAvatar, isNotNull);
    expect(selectedAvatar!.bytes, isNotEmpty);
    expect(selectedAvatar.fileExtension, 'jpg');
  });
}
