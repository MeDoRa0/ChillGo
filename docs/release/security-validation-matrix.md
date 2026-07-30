# Security validation matrix

Validate every protected resource for anonymous, outsider, removed, revoked or
expired invitation, and authorized actors. Every unauthorized read/write must
be denied; each authorized control must succeed.

| Resource family | Actions |
|---|---|
| Profiles and usernames | read, create, update |
| Crews, memberships, invitations | read, create, update, revoke |
| Outings, participants, agreements, commands | read, create, update |
| Chat and read state | read, create, expiry cleanup |
| Live meetup/location shares/transitions | read, create, update, cleanup |
| Notifications/preferences/unread counts | recipient read, direct-write denial |
| Avatar storage | upload, read, revoked access |
