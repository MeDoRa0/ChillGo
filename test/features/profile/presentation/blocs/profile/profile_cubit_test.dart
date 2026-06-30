import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chillgo/features/profile/presentation/blocs/profile/profile_cubit.dart';
import 'package:chillgo/features/profile/domain/repositories/profile_repository.dart';
import 'package:chillgo/features/authentication/domain/entities/user_profile.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late ProfileCubit profileCubit;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    profileCubit = ProfileCubit(profileRepository: mockProfileRepository);
  });

  group('ProfileCubit', () {
    final userProfile = UserProfile(
      id: 'test_uid',
      username: 'testuser',
      displayName: 'Test User',
      createdAt: DateTime.now(),
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits [ProfileLoading, ProfileLoaded] when loadProfile succeeds',
      build: () {
        when(
          () => mockProfileRepository.getProfile('test_uid'),
        ).thenAnswer((_) async => userProfile);
        return profileCubit;
      },
      act: (cubit) => cubit.loadProfile('test_uid'),
      expect: () => <ProfileState>[
        ProfileLoading(),
        ProfileLoaded(userProfile),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits [ProfileLoading, ProfileFailure] when loadProfile fails',
      build: () {
        when(
          () => mockProfileRepository.getProfile('test_uid'),
        ).thenThrow(Exception('Failed to fetch'));
        return profileCubit;
      },
      act: (cubit) => cubit.loadProfile('test_uid'),
      expect: () => <ProfileState>[
        ProfileLoading(),
        const ProfileFailure('Exception: Failed to fetch'),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits [ProfileLoading, ProfileLoaded] with updated display name',
      build: () {
        when(
          () => mockProfileRepository.updateProfile(
            uid: 'test_uid',
            displayName: 'Updated Name',
          ),
        ).thenAnswer((_) async {});
        return profileCubit;
      },
      seed: () => ProfileLoaded(userProfile),
      act: (cubit) => cubit.updateDisplayName('test_uid', 'Updated Name'),
      expect: () => <ProfileState>[
        ProfileLoading(),
        ProfileLoaded(
          UserProfile(
            id: 'test_uid',
            username: 'testuser',
            displayName: 'Updated Name',
            createdAt: userProfile.createdAt,
          ),
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits failure and restores loaded state when display name is invalid',
      build: () => profileCubit,
      seed: () => ProfileLoaded(userProfile),
      act: (cubit) => cubit.updateDisplayName('test_uid', '   '),
      expect: () => <ProfileState>[
        const ProfileFailure('Display name must be 1-50 characters'),
        ProfileLoaded(userProfile),
      ],
      verify: (_) {
        verifyNever(
          () => mockProfileRepository.updateProfile(
            uid: any(named: 'uid'),
            displayName: any(named: 'displayName'),
          ),
        );
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits [ProfileLoading, ProfileLoaded] with updated avatar url',
      build: () {
        when(
          () => mockProfileRepository.uploadAvatar(
            uid: 'test_uid',
            imageBytes: [1, 2, 3],
            fileExtension: 'jpg',
          ),
        ).thenAnswer((_) async => 'https://example.com/avatar.jpg');
        when(
          () => mockProfileRepository.updateProfile(
            uid: 'test_uid',
            avatarUrl: 'https://example.com/avatar.jpg',
          ),
        ).thenAnswer((_) async {});
        return profileCubit;
      },
      seed: () => ProfileLoaded(userProfile),
      act: (cubit) => cubit.updateAvatar('test_uid', [1, 2, 3], 'jpg'),
      expect: () => <ProfileState>[
        ProfileLoading(),
        ProfileLoaded(
          UserProfile(
            id: 'test_uid',
            username: 'testuser',
            displayName: 'Test User',
            avatarUrl: 'https://example.com/avatar.jpg',
            createdAt: userProfile.createdAt,
          ),
        ),
      ],
    );
  });
}
