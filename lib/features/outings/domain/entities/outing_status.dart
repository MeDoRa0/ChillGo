enum OutingStatus {
  draft('draft'),
  planning('planning'),
  confirmed('confirmed'),
  meeting('meeting'),
  completed('completed'),
  archived('archived'),
  cancelled('cancelled');

  final String value;

  const OutingStatus(this.value);

  static OutingStatus fromValue(Object? value) {
    if (value is! String) {
      throw FormatException('Invalid outing status: $value');
    }
    for (final status in OutingStatus.values) {
      if (status.value == value) return status;
    }
    throw FormatException('Invalid outing status: $value');
  }

  bool get isHistorical =>
      this == OutingStatus.completed ||
      this == OutingStatus.archived ||
      this == OutingStatus.cancelled;

  bool get isEditable =>
      this == OutingStatus.draft ||
      this == OutingStatus.planning ||
      this == OutingStatus.confirmed ||
      this == OutingStatus.meeting;

  bool get isCancellable =>
      this == OutingStatus.draft ||
      this == OutingStatus.planning ||
      this == OutingStatus.confirmed;
}
