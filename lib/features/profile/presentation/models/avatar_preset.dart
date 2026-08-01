class AvatarPreset {
  final String assetPath;
  final String semanticLabel;

  const AvatarPreset({required this.assetPath, required this.semanticLabel});
}

const avatarPresets = <AvatarPreset>[
  AvatarPreset(
    assetPath: 'assets/avatars/male_01.jpg',
    semanticLabel: 'Smiling cartoon character with curly hair and glasses',
  ),
  AvatarPreset(
    assetPath: 'assets/avatars/male_02.jpg',
    semanticLabel: 'Relaxed cartoon character with wavy hair and a teal hoodie',
  ),
  AvatarPreset(
    assetPath: 'assets/avatars/male_03.jpg',
    semanticLabel: 'Laughing cartoon character with close-cropped hair',
  ),
  AvatarPreset(
    assetPath: 'assets/avatars/male_04.jpg',
    semanticLabel: 'Playful cartoon character with tousled red hair',
  ),
  AvatarPreset(
    assetPath: 'assets/avatars/male_05.jpg',
    semanticLabel: 'Calm cartoon character with short black hair',
  ),
  AvatarPreset(
    assetPath: 'assets/avatars/female_01.jpg',
    semanticLabel: 'Smiling cartoon character with braided hair',
  ),
  AvatarPreset(
    assetPath: 'assets/avatars/female_02.jpg',
    semanticLabel: 'Cheerful cartoon character with curls and a coral headband',
  ),
  AvatarPreset(
    assetPath: 'assets/avatars/female_03.jpg',
    semanticLabel: 'Curious cartoon character with red hair and glasses',
  ),
  AvatarPreset(
    assetPath: 'assets/avatars/female_04.jpg',
    semanticLabel: 'Serene cartoon character with a long dark ponytail',
  ),
  AvatarPreset(
    assetPath: 'assets/avatars/female_05.jpg',
    semanticLabel: 'Winking cartoon character with a short black bob',
  ),
];
