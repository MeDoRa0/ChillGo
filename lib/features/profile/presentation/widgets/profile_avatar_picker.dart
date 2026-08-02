import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/presentation/theme/chillgo_colors.dart';
import '../models/avatar_preset.dart';

class ProfileAvatarSelection {
  final AvatarPreset? preset;
  final Uint8List? uploadedBytes;

  const ProfileAvatarSelection({this.preset, this.uploadedBytes})
    : assert(preset == null || uploadedBytes == null);
}

class ProfileAvatarPicker extends StatelessWidget {
  final ProfileAvatarSelection selection;
  final bool enabled;
  final ValueChanged<AvatarPreset> onPresetSelected;
  final VoidCallback onUploadPressed;

  const ProfileAvatarPicker({
    required this.selection,
    required this.enabled,
    required this.onPresetSelected,
    required this.onUploadPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _AvatarPreview(selection: selection)),
        const SizedBox(height: 16),
        _buildIntroduction(),
        const SizedBox(height: 14),
        AvatarPresetGrid(
          selectedPreset: selection.preset,
          enabled: enabled,
          onPresetSelected: onPresetSelected,
        ),
        const SizedBox(height: 14),
        _buildUploadButton(),
      ],
    );
  }

  Widget _buildIntroduction() {
    return const Column(
      children: [
        Text(
          'Choose your avatar',
          style: TextStyle(
            color: ChillGoColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Pick a character or upload your own photo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ChillGoColors.inkMuted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return OutlinedButton.icon(
      key: const ValueKey('upload-profile-photo'),
      onPressed: enabled ? onUploadPressed : null,
      icon: const Icon(Icons.add_a_photo_outlined),
      label: Text(
        selection.uploadedBytes == null ? 'Upload photo' : 'Change photo',
      ),
    );
  }
}

class AvatarPresetGrid extends StatelessWidget {
  final AvatarPreset? selectedPreset;
  final bool enabled;
  final ValueChanged<AvatarPreset> onPresetSelected;

  const AvatarPresetGrid({
    required this.selectedPreset,
    required this.enabled,
    required this.onPresetSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const ValueKey('avatar-preset-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: avatarPresets.length,
      itemBuilder: (context, index) => _buildPresetButton(index),
    );
  }

  Widget _buildPresetButton(int index) {
    final preset = avatarPresets[index];
    return _PresetAvatarButton(
      key: ValueKey('avatar-preset-$index'),
      preset: preset,
      selected: preset.assetPath == selectedPreset?.assetPath,
      enabled: enabled,
      onPressed: () => onPresetSelected(preset),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  final ProfileAvatarSelection selection;

  const _AvatarPreview({required this.selection});

  bool get _hasAvatar =>
      selection.uploadedBytes != null || selection.preset != null;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: _hasAvatar,
      label: _hasAvatar
          ? 'Selected profile avatar preview'
          : 'No avatar selected',
      child: Container(
        width: 104,
        height: 104,
        padding: const EdgeInsets.all(4),
        decoration: _previewDecoration(),
        child: ClipOval(child: _buildAvatar()),
      ),
    );
  }

  BoxDecoration _previewDecoration() {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: ChillGoColors.surface,
      border: Border.all(
        color: _hasAvatar ? ChillGoColors.coral : ChillGoColors.outline,
        width: _hasAvatar ? 3 : 2,
      ),
    );
  }

  Widget _buildAvatar() {
    if (selection.uploadedBytes case final bytes?) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    if (selection.preset case final preset?) {
      return Image.asset(preset.assetPath, fit: BoxFit.cover);
    }
    return const ColoredBox(
      color: ChillGoColors.sunshineSoft,
      child: Icon(Icons.face_rounded, size: 58, color: ChillGoColors.coral),
    );
  }
}

class _PresetAvatarButton extends StatelessWidget {
  final AvatarPreset preset;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  const _PresetAvatarButton({
    required this.preset,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: preset.semanticLabel,
      child: Tooltip(
        message: preset.semanticLabel,
        child: Material(color: Colors.transparent, child: _buildButton()),
      ),
    );
  }

  Widget _buildButton() {
    return InkWell(
      onTap: enabled ? onPressed : null,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(3),
        decoration: _buttonDecoration(),
        child: _buildAvatarStack(),
      ),
    );
  }

  BoxDecoration _buttonDecoration() {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: ChillGoColors.surface,
      border: Border.all(
        color: selected ? ChillGoColors.coral : ChillGoColors.outline,
        width: selected ? 3 : 1,
      ),
    );
  }

  Widget _buildAvatarStack() {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        ClipOval(child: Image.asset(preset.assetPath, fit: BoxFit.cover)),
        if (selected) const _SelectedAvatarMark(),
      ],
    );
  }
}

class _SelectedAvatarMark extends StatelessWidget {
  const _SelectedAvatarMark();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      right: -5,
      bottom: -5,
      child: CircleAvatar(
        radius: 10,
        backgroundColor: ChillGoColors.coral,
        child: Icon(Icons.check, size: 14, color: Colors.white),
      ),
    );
  }
}
