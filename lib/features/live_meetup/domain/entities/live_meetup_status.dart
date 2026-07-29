enum LiveMeetupStatus {
  gettingReady('getting_ready', 'Getting Ready'),
  onMyWay('on_my_way', 'On My Way'),
  arrived('arrived', 'Arrived');

  const LiveMeetupStatus(this.value, this.label);
  final String value;
  final String label;

  static LiveMeetupStatus fromValue(Object? value) => values.firstWhere(
    (status) => status.value == value,
    orElse: () => throw FormatException('Invalid live meetup status: $value'),
  );
}
