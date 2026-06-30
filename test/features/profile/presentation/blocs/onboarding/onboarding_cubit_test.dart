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
    
    // Stub forceRefreshStatus
    when(() => mockAuthRepository.forceRefreshStatus()).thenAnswer((_) async {});
    
    onboardingCubit = OnboardingCubit(
      profileRepository: mockProfileRepository,
      authRepository: mockAuthRepository,
    );
  });

  group('OnboardingCubit', () {
    blocTest<OnboardingCubit, OnboardingState>(
      'emits [OnboardingLoading, OnboardingSuccess] when username is available and profile creation succeeds',
      build: () {
        when(() => mockProfileRepository.isUsernameAvailable('newuser')).thenAnswer((_) async => true);
        when(() => mockProfileRepository.createProfile(
          uid: 'test_uid',
          username: 'newuser',
          displayName: 'New User',
        )).thenAnswer((_) async {});
        return onboardingCubit;
      },
      act: (cubit) => cubit.submitOnboarding(
        uid: 'test_uid',
        username: 'newuser',
        displayName: 'New User',
      ),
      expect: () => <OnboardingState>[
        OnboardingLoading(),
        OnboardingSuccess(),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'emits [OnboardingLoading, OnboardingFailure] when username is already taken',
      build: () {
        when(() => mockProfileRepository.isUsernameAvailable('takenuser')).thenAnswer((_) async => false);
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
        when(() => mockProfileRepository.isUsernameAvailable('newuser')).thenAnswer((_) async => true);
        when(() => mockProfileRepository.createProfile(
          uid: 'test_uid',
          username: 'newuser',
          displayName: 'New User',
        )).thenAnswer((_) async {});
        when(() => mockAuthRepository.forceRefreshStatus()).thenThrow(Exception('Auth refresh failed'));
        return onboardingCubit;
      },
      act: (cubit) => cubit.submitOnboarding(
        uid: 'test_uid',
        username: 'newuser',
        displayName: 'New User',
      ),
      expect: () => <OnboardingState>[
        OnboardingLoading(),
        OnboardingSuccess(),
      ],
    );
  });
}
