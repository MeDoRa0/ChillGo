import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/avatar_preset.dart';
import '../utils/image_helper.dart';
import 'profile_avatar_picker.dart';

sealed class AvatarChangeChoice {
  const AvatarChangeChoice();
}

final class PresetAvatarChoice extends AvatarChangeChoice {
  final AvatarPreset preset;

  const PresetAvatarChoice(this.preset);
}

final class DeviceAvatarChoice extends AvatarChangeChoice {
  final ImageSource source;

  const DeviceAvatarChoice(this.source);
}

Future<AvatarChangeChoice?> showAvatarSourceSheet(BuildContext context) {
  return showModalBottomSheet<AvatarChangeChoice>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AvatarSourceSheet(),
  );
}

Future<ImageSource?> showDeviceAvatarSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (_) => const _DeviceAvatarSourceSheet(),
  );
}

Future<PickedAvatar?> prepareAvatarChange(
  AvatarChangeChoice choice,
  ImageHelper imageHelper,
) async {
  return switch (choice) {
    PresetAvatarChoice(:final preset) => _loadPresetAvatar(preset),
    DeviceAvatarChoice(:final source) => imageHelper.pickAndCompressAvatar(
      source,
    ),
  };
}

Future<PickedAvatar> _loadPresetAvatar(AvatarPreset preset) async {
  final assetBytes = await rootBundle.load(preset.assetPath);
  return PickedAvatar(
    bytes: assetBytes.buffer.asUint8List(
      assetBytes.offsetInBytes,
      assetBytes.lengthInBytes,
    ),
    fileExtension: 'jpg',
  );
}

class _AvatarSourceSheet extends StatelessWidget {
  const _AvatarSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Change avatar',
              key: Key('change-avatar-option'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _presetGrid(context),
            const SizedBox(height: 12),
            const Divider(),
            _DeviceAvatarSourceTiles(
              onSelected: (source) =>
                  Navigator.of(context).pop(DeviceAvatarChoice(source)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetGrid(BuildContext context) {
    return AvatarPresetGrid(
      selectedPreset: null,
      enabled: true,
      onPresetSelected: (preset) =>
          Navigator.of(context).pop(PresetAvatarChoice(preset)),
    );
  }
}

class _DeviceAvatarSourceSheet extends StatelessWidget {
  const _DeviceAvatarSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _DeviceAvatarSourceTiles(
        onSelected: (source) => Navigator.of(context).pop(source),
      ),
    );
  }
}

class _DeviceAvatarSourceTiles extends StatelessWidget {
  final ValueChanged<ImageSource> onSelected;

  const _DeviceAvatarSourceTiles({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Photo library'),
          onTap: () => onSelected(ImageSource.gallery),
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: const Text('Camera'),
          onTap: () => onSelected(ImageSource.camera),
        ),
      ],
    );
  }
}
