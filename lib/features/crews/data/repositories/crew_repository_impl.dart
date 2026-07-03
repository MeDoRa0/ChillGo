import '../../domain/entities/crew.dart';
import '../../domain/entities/crew_membership.dart';
import '../../domain/entities/crew_invitation.dart';
import '../../domain/repositories/crew_repository.dart';
import '../datasources/firestore_crews_datasource.dart';

class CrewRepositoryImpl implements CrewRepository {
  final FirestoreCrewsDatasource datasource;

  /// The currently authenticated user's uid. Must be set before use.
  final String Function() currentUid;

  /// The currently authenticated user's profile data accessors.
  final String Function() currentUsername;
  final String Function() currentDisplayName;

  CrewRepositoryImpl({
    required this.datasource,
    required this.currentUid,
    required this.currentUsername,
    required this.currentDisplayName,
  });

  @override
  Future<String> createCrew(String name) async {
    if (name.trim().length < 3 || name.trim().length > 50) {
      throw Exception('Crew name must be between 3 and 50 characters.');
    }
    return datasource.createCrew(name: name, ownerId: currentUid());
  }

  @override
  Stream<List<Crew>> streamCrews() {
    return datasource.streamCrewsForUser(currentUid());
  }

  @override
  Stream<Crew?> streamCrew(String crewId) {
    return datasource.streamCrew(crewId);
  }

  @override
  Stream<List<CrewMembership>> streamMembers(String crewId) {
    return datasource.streamMembers(crewId);
  }

  @override
  Future<void> inviteUser(String crewId, String username) async {
    // Fetch crew for cached name
    final crew = await datasource.streamCrew(crewId).first;
    if (crew == null) throw Exception('crew-not-found');

    await datasource.inviteUser(
      crewId: crewId,
      inviterUid: currentUid(),
      inviterUsername: currentUsername(),
      inviterDisplayName: currentDisplayName(),
      crewName: crew.name,
      targetUsername: username,
    );
  }

  @override
  Stream<List<CrewInvitation>> streamPendingInvitationsForCrew(String crewId) {
    return datasource.streamPendingInvitationsForCrew(crewId);
  }

  @override
  Stream<List<CrewInvitation>> streamReceivedInvitations() {
    return datasource.streamReceivedInvitations(currentUid());
  }

  @override
  Future<void> acceptInvitation(String invitationId) async {
    await datasource.acceptInvitation(
      invitationId: invitationId,
      userId: currentUid(),
    );
  }

  @override
  Future<void> rejectInvitation(String invitationId) async {
    await datasource.rejectInvitation(invitationId);
  }

  @override
  Future<void> updateCrewName(String crewId, String name) async {
    if (name.trim().length < 3 || name.trim().length > 50) {
      throw Exception('Crew name must be between 3 and 50 characters.');
    }
    await datasource.updateCrewName(crewId, name);
  }

  @override
  Future<void> deleteCrew(String crewId) async {
    await datasource.deleteCrew(crewId);
  }

  @override
  Future<void> leaveCrew(String crewId) async {
    final crew = await datasource.streamCrew(crewId).first;
    if (crew == null) throw Exception('crew-not-found');
    if (crew.ownerId == currentUid()) {
      throw Exception('owner-cannot-leave-crew');
    }
    await datasource.removeMember(crewId, currentUid());
  }

  @override
  Future<void> removeMember(String crewId, String userId) async {
    await datasource.removeMember(crewId, userId);
  }
}
