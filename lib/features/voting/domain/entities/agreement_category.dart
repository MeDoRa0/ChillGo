enum AgreementCategory {
  time('time'),
  location('location');

  const AgreementCategory(this.value);
  final String value;

  static AgreementCategory fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Invalid agreement category: $value'),
  );
}
