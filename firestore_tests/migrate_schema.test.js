const assert = require('assert');
const {
  addPhase4Defaults,
  fieldsChanged,
  removeDeprecatedFields,
} = require('./migrate_schema');
describe('Phase 4 schema migration', () => {
  it('removes the deprecated creation timestamp only from crews', () => {
    const crewFields = {
      name: { stringValue: 'Weekend Hikers' },
      ownerId: { stringValue: 'alice' },
      createdAt: { timestampValue: '2026-07-01T00:00:00.000Z' },
    };
    const invitationFields = structuredClone(crewFields);

    removeDeprecatedFields('crews', crewFields);
    removeDeprecatedFields('crew_invitations', invitationFields);

    assert.equal('createdAt' in crewFields, false);
    assert.equal('createdAt' in invitationFields, true);
  });

  it('backfills creator acceptance and invite defaults', () => {
    const when = new Date('2026-07-11T00:00:00Z');
    const creator = addPhase4Defaults('outing_participants', { isCreatorParticipant: { booleanValue: true } }, when);
    const invite = addPhase4Defaults('outing_participants', { isCreatorParticipant: { booleanValue: false } }, when);
    assert.equal(creator.attendanceStatus.stringValue, 'accepted'); assert.equal(creator.respondedAt.timestampValue, when.toISOString());
    assert.equal(invite.attendanceStatus.stringValue, 'invited'); assert.equal(invite.respondedAt.nullValue, null);
  });
  it('is idempotent and adds outing sequence once', () => {
    const fields = addPhase4Defaults('outings', {}); const snapshot = structuredClone(fields);
    addPhase4Defaults('outings', fields); assert.equal(fieldsChanged(snapshot, fields), false); assert.equal(fields.agreementRoundSequence.integerValue, '0');
  });
});
