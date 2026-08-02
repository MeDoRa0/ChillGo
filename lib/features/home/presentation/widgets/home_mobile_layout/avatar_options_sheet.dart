part of '../home_mobile_layout.dart';

Future<void> _showAvatarOptions(BuildContext context) async {
  final choice = await showAvatarSourceSheet(context);
  if (choice == null || !context.mounted) return;
  await _changeHomeAvatar(context, choice);
}

Future<void> _changeHomeAvatar(
  BuildContext context,
  AvatarChangeChoice choice,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await _pickAndSaveHomeAvatar(context, choice);
  } on PlatformException catch (error) {
    _showAvatarPickerFailure(
      messenger,
      error.message ?? 'Could not open photo.',
    );
  } on FormatException catch (error) {
    _showAvatarPickerFailure(messenger, error.message);
  } on StateError catch (error) {
    _showAvatarPickerFailure(messenger, error.message);
  } on FlutterError {
    _showAvatarPickerFailure(messenger, 'Could not prepare that avatar.');
  }
}

Future<void> _pickAndSaveHomeAvatar(
  BuildContext context,
  AvatarChangeChoice choice,
) async {
  final avatar = await prepareAvatarChange(choice, ImageHelper());
  if (avatar == null || !context.mounted) return;

  final uid = context.read<AuthBloc>().state.credentials?.uid;
  if (uid == null) return;
  await context.read<ProfileCubit>().updateAvatar(
    uid,
    avatar.bytes,
    avatar.fileExtension,
  );
}

void _showAvatarPickerFailure(
  ScaffoldMessengerState messenger,
  String message,
) {
  if (!messenger.mounted) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), backgroundColor: ChillGoColors.danger),
    );
}
