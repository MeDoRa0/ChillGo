// Firebase's sealed Firestore types need mocktail's test-only implementations.
// ignore_for_file: subtype_of_sealed_class

import 'package:chillgo/features/notifications/data/datasources/firestore_notifications_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  test('emits an empty page when a new user has no summary document', () async {
    final firestore = _MockFirestore();
    final summaries = _MockCollectionReference();
    final summary = _MockDocumentReference();
    final snapshot = _MockDocumentSnapshot();
    final functions = _MockFunctions();
    when(
      () => firestore.collection('notification_summaries'),
    ).thenReturn(summaries);
    when(() => summaries.doc('user-1')).thenReturn(summary);
    when(() => summary.snapshots()).thenAnswer((_) => Stream.value(snapshot));
    when(() => snapshot.exists).thenReturn(false);
    when(() => snapshot.data()).thenReturn(null);

    final datasource = FirestoreNotificationsDatasource(
      firestore: firestore,
      functions: functions,
      currentUid: () => 'user-1',
    );

    await expectLater(
      datasource.watchNewest(),
      emits(const NotificationDataPage(items: [])),
    );
    verifyNever(() => functions.httpsCallable('notificationCenterPage'));
  });
}

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}
