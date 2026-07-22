import '../../../outings/domain/entities/outing_status.dart';

enum ChatAccess { inaccessible, readOnly, writable }

class ChatAccessPolicy {
  const ChatAccessPolicy();

  ChatAccess evaluate({
    required OutingStatus status,
    required bool isCrewMember,
    required bool isParticipant,
    bool deletionPending = false,
  }) {
    if (!isCrewMember || !isParticipant || deletionPending) {
      return ChatAccess.inaccessible;
    }
    return status.isEditable ? ChatAccess.writable : ChatAccess.readOnly;
  }
}
