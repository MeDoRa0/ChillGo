import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? readFirestoreTimestamp(Object? rawTimestamp) {
  if (rawTimestamp is Timestamp) {
    return rawTimestamp.toDate().toUtc();
  }
  if (rawTimestamp is DateTime) {
    return rawTimestamp.toUtc();
  }
  if (rawTimestamp is String) {
    return DateTime.tryParse(rawTimestamp)?.toUtc();
  }
  return null;
}

Timestamp writeFirestoreTimestamp(DateTime dateTime) {
  return Timestamp.fromDate(dateTime.toUtc());
}
