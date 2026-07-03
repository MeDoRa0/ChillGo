# Crew Management Walkthrough

This walkthrough is the manual validation artifact for Phase 2 Crew Management. It complements the automated checks in [quickstart.md](./quickstart.md) by covering the complete user-facing flow across owner and member accounts.

## Prerequisites

- Run the app with Firebase Auth and Firestore configured for a local or test environment.
- Use two signed-in test users:
  - Owner: username `alice_cool`, display name `Alice`
  - Invitee: username `bob_chill`, display name `Bob`
- Start from a clean test state with no existing crew named `Weekend Hikers` and no pending invitation between these users.

## Automated Checks

Run these before manual verification:

```bash
flutter test --no-pub test/features/crews
cd firestore_tests && npm test
```

Expected result:

- Crew feature unit, datasource, repository, and Cubit tests pass.
- Firestore rules tests confirm non-members cannot read crews, non-owners cannot manage crews or members, invited users can accept or reject invitations, owners can revoke invitations, and duplicate membership/invitation states are rejected.

## Scenario 1: Create Crew And View Members

1. Sign in as Alice.
2. Open the Crews screen.
3. Create a crew named `Weekend Hikers`.
4. Verify Alice lands on the crew details screen.
5. Verify the crew title is `Weekend Hikers`.
6. Verify the members list contains exactly Alice with the owner role.

Pass criteria:

- The crew appears in Alice's crews list.
- The details screen shows Alice as `Owner`.
- No duplicate owner membership is created after refreshing the screen.

## Scenario 2: Invite By Username

1. Stay signed in as Alice.
2. Open `Weekend Hikers`.
3. Invite `bob_chill`.
4. Verify Bob appears in the pending invitations list.
5. Attempt to invite `bob_chill` again.
6. Attempt to invite a non-existent username such as `nobody_here`.

Pass criteria:

- The first invite succeeds and appears immediately.
- The duplicate invite is rejected with a clear pending-invitation message.
- The unknown username is rejected with a clear username-not-found message.
- Bob is not added to the member list until he accepts.

## Scenario 3: Accept Invitation

1. Sign in as Bob in a second app instance or after signing Alice out.
2. Open the Invitations screen.
3. Verify the pending invitation to `Weekend Hikers` from Alice is visible.
4. Accept the invitation.
5. Open Bob's crews list.
6. Open `Weekend Hikers`.

Pass criteria:

- The invitation disappears after acceptance.
- `Weekend Hikers` appears in Bob's crews list.
- The member list shows Alice as `Owner` and Bob as `Member`.
- Alice's open crew details screen receives the membership update in real time.

## Scenario 4: Leave Crew

1. Stay signed in as Bob.
2. Open `Weekend Hikers`.
3. Choose Leave Crew and confirm.
4. Return to Bob's crews list.

Pass criteria:

- Bob is removed from `Weekend Hikers`.
- `Weekend Hikers` no longer appears in Bob's crews list.
- Alice's crew details screen removes Bob from the member list in real time.
- Alice remains the owner and cannot use the leave flow to leave her own crew.

## Scenario 5: Reject Invitation

1. Sign in as Alice and invite `bob_chill` again.
2. Sign in as Bob.
3. Open the Invitations screen.
4. Reject the invitation.

Pass criteria:

- The invitation disappears after rejection.
- Bob is not added as a member.
- Alice no longer sees Bob in the pending invitations list.

## Scenario 6: Revoke Pending Invitation

1. Sign in as Alice.
2. Invite `bob_chill`.
3. Verify Bob appears in pending invitations.
4. Revoke Bob's pending invitation.
5. Sign in as Bob and open Invitations.

Pass criteria:

- Bob is removed from Alice's pending invitations list.
- Bob does not see the revoked invitation.
- Bob is not added as a member.

## Scenario 7: Edit Crew Name

1. Sign in as Alice.
2. Open `Weekend Hikers`.
3. Edit the crew name to `Weekend Trail Crew`.
4. Save the change.
5. Refresh or reopen the crew list.

Pass criteria:

- The new name appears on the details screen.
- The new name appears in Alice's crews list.
- Active members see the updated name.
- Invalid names shorter than 3 characters or longer than 50 characters are rejected.

## Scenario 8: Owner Removes Member

1. Sign in as Alice and ensure Bob is a member of `Weekend Trail Crew`.
2. Open the members list.
3. Remove Bob and confirm.
4. Sign in as Bob and open the crews list.

Pass criteria:

- Bob is removed from the members list.
- Bob no longer sees the crew in his crews list.
- Alice cannot remove herself as owner through the member removal action.

## Scenario 9: Delete Crew

1. Sign in as Alice.
2. Open `Weekend Trail Crew`.
3. Choose Delete Crew and confirm.
4. Return to the crews list.
5. Sign in as Bob and open the crews list and invitations screen.

Pass criteria:

- The crew no longer appears for Alice.
- The crew no longer appears for any removed or former member.
- Related crew memberships and pending invitations for that crew are cleaned up.
- Outing cleanup remains deferred to the Outing Management phase as documented in [spec.md](./spec.md).

## Responsive Verification

Verify the primary crew screens on a narrow mobile viewport and a wider desktop or web viewport:

- Crews list
- Crew details
- Invite member dialog
- Invitations screen
- Edit, delete, leave, remove, and revoke confirmation dialogs

Pass criteria:

- Text remains readable and does not overlap controls.
- Member and invitation lists scroll smoothly with enough rows to exercise scrolling.
- Owner-only actions are not shown to standard members.
- Destructive actions require confirmation.

## Completion Checklist

- [ ] Automated crew tests passed.
- [ ] Firestore rules tests passed.
- [ ] Scenario 1 passed.
- [ ] Scenario 2 passed.
- [ ] Scenario 3 passed.
- [ ] Scenario 4 passed.
- [ ] Scenario 5 passed.
- [ ] Scenario 6 passed.
- [ ] Scenario 7 passed.
- [ ] Scenario 8 passed.
- [ ] Scenario 9 passed.
- [ ] Responsive verification passed.
