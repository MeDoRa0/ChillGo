import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/presentation/widgets/app_back_button.dart';
import '../../../../core/presentation/theme/chillgo_colors.dart';
import '../../../../core/presentation/widgets/responsive_content.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';
import '../../../../core/presentation/widgets/sunshine_background.dart';
import '../../../authentication/presentation/blocs/auth/auth_bloc.dart';
import '../../../authentication/presentation/blocs/auth/auth_state.dart';
import '../../../authentication/presentation/blocs/auth/auth_event.dart';
import '../blocs/profile/profile_cubit.dart';
import '../utils/image_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => prev.credentials?.uid != curr.credentials?.uid,
      builder: (context, authState) {
        final uid = authState.credentials?.uid;

        if (uid == null) {
          return const Scaffold(body: ShimmerListPlaceholder(itemCount: 3));
        }

        return BlocProvider(
          create: (_) => sl<ProfileCubit>()..loadProfile(uid),
          child: _ProfileView(uid: uid),
        );
      },
    );
  }
}

class _ProfileView extends StatefulWidget {
  final String uid;

  const _ProfileView({required this.uid});

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final ImageHelper _imageHelper = ImageHelper();
  bool _isPickingAvatar = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Profile'),
      ),
      body: SunshineBackground(
        child: ResponsiveContent(
          maxWidth: 640,
          child: BlocConsumer<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state is ProfileFailure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.error)));
              }
            },
            builder: (context, state) {
              if (state is ProfileInitial ||
                  state is ProfileLoading && state is! ProfileLoaded) {
                return const ShimmerListPlaceholder(itemCount: 3);
              }

              final loadedState = state is ProfileLoaded ? state : null;
              final profile = loadedState?.profile;
              if (profile == null) {
                return const Center(
                  child: Text(
                    'Profile unavailable',
                    style: TextStyle(color: ChillGoColors.inkMuted),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: ChillGoColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: ChillGoColors.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: ChillGoColors.sunshineSoft,
                              backgroundImage: profile.avatarUrl != null
                                  ? NetworkImage(profile.avatarUrl!)
                                  : null,
                              child: profile.avatarUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: ChillGoColors.coral,
                                    )
                                  : null,
                            ),
                            IconButton.filled(
                              tooltip: 'Change avatar',
                              onPressed: _isPickingAvatar
                                  ? null
                                  : () => _showAvatarSourceSheet(context),
                              icon: _isPickingAvatar
                                  ? const ShimmerBox(
                                      width: 18,
                                      height: 18,
                                      shape: BoxShape.circle,
                                      semanticLabel: 'Updating avatar',
                                    )
                                  : const Icon(Icons.photo_camera),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              profile.displayName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ChillGoColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Edit display name',
                            onPressed: () => _showEditDisplayNameDialog(
                              context,
                              profile.displayName,
                            ),
                            icon: const Icon(
                              Icons.edit,
                              color: ChillGoColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '@${profile.username}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: ChillGoColors.inkMuted,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ChillGoColors.danger,
                          side: const BorderSide(color: ChillGoColors.danger),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAvatarSourceSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;
    await _pickAvatar(source);
  }

  Future<void> _pickAvatar(ImageSource source) async {
    setState(() => _isPickingAvatar = true);
    try {
      final avatar = await _imageHelper.pickAndCompressAvatar(source);
      if (avatar != null && mounted) {
        await context.read<ProfileCubit>().updateAvatar(
          widget.uid,
          avatar.bytes,
          avatar.fileExtension,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isPickingAvatar = false);
    }
  }

  Future<void> _showEditDisplayNameDialog(
    BuildContext context,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final displayName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (displayName == null || !context.mounted) return;

    await context.read<ProfileCubit>().updateDisplayName(
      widget.uid,
      displayName,
    );
  }
}
