enum CrewRole {
  owner,
  member;

  String get value {
    switch (this) {
      case CrewRole.owner:
        return 'owner';
      case CrewRole.member:
        return 'member';
    }
  }

  static CrewRole fromValue(String? value) {
    switch (value) {
      case 'owner':
        return CrewRole.owner;
      case 'member':
      default:
        return CrewRole.member;
    }
  }
}
