import 'package:chillgo/features/profile/presentation/models/avatar_preset.dart';
import 'package:chillgo/features/profile/presentation/widgets/profile_avatar_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows all presets and reports the selected character', (
    tester,
  ) async {
    AvatarPreset? selectedPreset;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: ProfileAvatarPicker(
              selection: const ProfileAvatarSelection(),
              enabled: true,
              onPresetSelected: (preset) => selectedPreset = preset,
              onUploadPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('avatar-preset-grid')), findsOneWidget);
    for (var index = 0; index < avatarPresets.length; index++) {
      expect(find.byKey(ValueKey('avatar-preset-$index')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('avatar-preset-7')));
    expect(selectedPreset, avatarPresets[7]);
  });

  testWidgets('disables photo upload with the rest of the picker', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: ProfileAvatarPicker(
              selection: const ProfileAvatarSelection(),
              enabled: false,
              onPresetSelected: (_) {},
              onUploadPressed: () {},
            ),
          ),
        ),
      ),
    );

    final uploadButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('upload-profile-photo')),
    );
    expect(uploadButton.onPressed, isNull);
  });
}
