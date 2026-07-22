enum AttendanceStatus {
  invited('invited'),
  accepted('accepted'),
  declined('declined');

  const AttendanceStatus(this.value);
  final String value;
  static AttendanceStatus fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Invalid attendance status: $value'),
  );
}
