import '../entities/crew.dart';
import '../entities/crew_membership.dart';
import '../entities/crew_invitation.dart';

abstract class CrewRepository {
  Future<String> createCrew(String name);
  Future<bool> usernameExists(String username);
  Stream<List<Crew>> streamCrews();
  Stream<Crew?> streamCrew(String crewId);
  Stream<List<CrewMembership>> streamMembers(String crewId);
  Future<void> inviteUser(String crewId, String username);
  Stream<List<CrewInvitation>> streamPendingInvitationsForCrew(String crewId);
  Stream<List<CrewInvitation>> streamReceivedInvitations();
  Future<void> acceptInvitation(String invitationId);
  Future<void> rejectInvitation(String invitationId);
  Future<void> updateCrewName(String crewId, String name);
  Future<void> deleteCrew(String crewId);
  Future<void> leaveCrew(String crewId);
  Future<void> removeMember(String crewId, String userId);
}
