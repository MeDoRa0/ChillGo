import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chillgo/features/profile/presentation/blocs/onboarding/onboarding_cubit.dart';
import 'package:chillgo/features/profile/domain/repositories/profile_repository.dart';

import 'package:chillgo/features/authentication/domain/repositories/auth_repository.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late MockAuthRepository mockAuthRepository;
  late OnboardingCubit onboardingCubit;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    mockAuthRepository = MockAuthRepository();

    when(
      () => mockAuthRepository.refreshCurrentUserToken(),
    ).thenAnswer((_) async => const UserCredentials(uid: 'test_uid'));
    when(
      () => mockAuthRepository.forceRefreshStatus(),
    ).thenAnswer((_) async {});

    onboardingCubit = OnboardingCubit(
      profileRepository: mockProfileRepository,
      authRepository: mockAuthRepository,
    );
  });

  group('OnboardingCubit', () {
    blocTest<OnboardingCubit, OnboardingState>(
      'emits [OnboardingLoading, OnboardingSuccess] when username is available and profile creation succeeds',
      build: () {
        when(
          () => mockProfileRepository.isUsernameAvailable('newuser'),
        ).thenAnswer((_) async => true);
        when(
          () => mockProfileRepository.createProfile(
            uid: 'test_uid',
            username: 'newuser',
            displayName: 'New User',
          ),
        ).thenAnswer((_) async {});
        return onboardingCubit;
      },
      act: (cubit) => cubit.submitOnboarding(
        uid: 'test_uid',
        username: 'newuser',
        displayName: 'New User',
      ),
      expect: () => <OnboardingState>[OnboardingLoading(), OnboardingSuccess()],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'uses refreshed authenticated uid when creating profile',
      build: () {
        when(
          () => mockAuthRepository.refreshCurrentUserToken(),
        ).thenAnswer((_) async => const UserCredentials(uid: 'auth_uid'));
        when(
          () => mockProfileRepository.isUsernameAvailable('newuser'),
        ).thenAnswer((_) async => true);
        when(
          () => mockProfileRepository.createProfile(
            uid: 'auth_uid',
            username: 'newuser',
            displayName: 'New User',
          ),
        ).thenAnswer((_) async {});
        return onboardingCubit;
      },
      act: (cubit) => cubit.submitOnboarding(
        uid: 'stale_uid',
        username: 'newuser',
        displayName: 'New User',
      ),
      expect: () => <OnboardingState>[OnboardingLoading(), OnboardingSuccess()],
      verify: (_) {
        verify(
          () => mockProfileRepository.createProfile(
            uid: 'auth_uid',
            username: 'newuser',
            displayName: 'New User',
          ),
        ).called(1);
      },
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'uploads the selected avatar and creates the profile with its URL',
      build: () {
        when(
          () => mockProfileRepository.isUsernameAvailable('newuser'),
        ).thenAnswer((_) async => true);
        when(
          () => mockProfileRepository.uploadAvatar(
            uid: 'test_uid',
            imageBytes: const [1, 2, 3],
            fileExtension: 'jpg',
          ),
        ).thenAnswer((_) async => 'https://example.com/avatar.jpg');
        when(
          () => mockProfileRepository.createProfile(
            uid: 'test_uid',
            username: 'newuser',
            displayName: 'New User',
            avatarUrl: 'https://example.com/avatar.jpg',
          ),
        ).thenAnswer((_) async {});
        return onboardingCubit;
      },
      act: (cubit) => cubit.submitOnboarding(
        uid: 'test_uid',
        username: 'newuser',
        displayName: 'New User',
        avatar: const OnboardingAvatar(bytes: [1, 2, 3], fileExtension: 'jpg'),
      ),
      expect: () => <OnboardingState>[OnboardingLoading(), OnboardingSuccess()],
      verify: (_) {
        verifyInOrder([
          () => mockProfileRepository.uploadAvatar(
            uid: 'test_uid',
            imageBytes: const [1, 2, 3],
            fileExtension: 'jpg',
          ),
          () => mockProfileRepository.createProfile(
            uid: 'test_uid',
            username: 'newuser',
            displayName: 'New User',
            avatarUrl: 'https://example.com/avatar.jpg',
          ),
        ]);
      },
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'emits [OnboardingLoading, OnboardingFailure] when authentication is lost',
      build: () {
        when(
          () => mockAuthRepository.refreshCurrentUserToken(),
        ).thenAnswer((_) async => null);
        return onboardingCubit;
      },
      act: (cubit) => cubit.submitOnboarding(
        uid: 'test_uid',
        username: 'newuser',
        displayName: 'New User',
      ),
      expect: () => <OnboardingState>[
        OnboardingLoading(),
        const OnboardingFailure('Authentication lost. Please sign in again.'),
      ],
      verify: (_) {
        verifyNever(() => mockProfileRepository.isUsernameAvailable(any()));
      },
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'emits [OnboardingLoading, OnboardingFailure] when username is already taken',
      build: () {
        when(
          () => mockProfileRepository.isUsernameAvailable('takenuser'),
        ).thenAnswer((_) async => false);
        return onboardingCubit;
      },
      act: (cubit) => cubit.submitOnboarding(
        uid: 'test_uid',
        username: 'takenuser',
        displayName: 'Taken User',
      ),
      expect: () => <OnboardingState>[
        OnboardingLoading(),
        const OnboardingFailure('Username is already taken'),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'emits [OnboardingLoading, OnboardingSuccess] when createProfile succeeds but forceRefreshStatus throws',
      build: () {
        when(
          () => mockProfileRepository.isUsernameAvailable('newuser'),
        ).thenAnswer((_) async => true);
        when(
          () => mockProfileRepository.createProfile(
            uid: 'test_uid',
            username: 'newuser',
            displayName: 'New User',
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockAuthRepository.forceRefreshStatus(),
        ).thenThrow(Exception('Auth refresh failed'));
        return onboardingCubit;
      },
      act: (cubit) => cubit.submitOnboarding(
        uid: 'test_uid',
        username: 'newuser',
        displayName: 'New User',
      ),
      expect: () => <OnboardingState>[OnboardingLoading(), OnboardingSuccess()],
    );
  });
}
