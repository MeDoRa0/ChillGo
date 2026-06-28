# ChillGo — Product Plan

> Version: 1.0
>
> Platform: Flutter
>
> Targets:
> - Android
> - iOS
> - Web
> - Windows
>
> Backend: Firebase
>
> Architecture:
> - Feature-First Architecture
> - Clean Architecture
> - Bloc/Cubit State Management

---

# Product Vision

ChillGo is a multi-platform application that helps groups of friends organize outings in a structured and collaborative way.

Instead of relying on scattered conversations across messaging applications, ChillGo provides a dedicated workflow for planning, discussing, agreeing on, and managing outings from creation to completion.

The application is built around Crews and Outings rather than friendships or social networking.

---

# Problem Statement

Organizing outings between friends is often frustrating because:

- People suggest different locations.
- People suggest different times.
- Decisions get lost inside chat conversations.
- Nobody knows who is actually attending.
- Last-minute changes create confusion.
- Members arrive at different times with no visibility.

ChillGo centralizes the entire process into a structured experience.

---

# Core Philosophy

## Crew First

ChillGo is not a social network.

Users cannot add friends directly.

Relationships only exist inside Crews.

To interact with another user:

1. Create a Crew.
2. Invite members using their username.
3. Members join the Crew.
4. Outings are created inside the Crew.

There are no:

- Friend Requests
- Friend Lists
- Followers
- Social Feed

---

# Core Concepts

## User

A registered application user.

### Responsibilities

- Create Crews
- Join Crews
- Participate in Outings
- Vote on decisions
- Share live status

### User Profile

Each user has:

- Firebase UID
- Username (Unique)
- Display Name
- Avatar
- Created Date

---

## Crew

A persistent group of users.

Examples:

- School Friends
- Football Friends
- Work Friends
- Family

### Crew Capabilities

- Create Crew
- Edit Crew
- Delete Crew
- Invite Members
- Remove Members
- Leave Crew
- View Crew Outings

---

## Outing

An event organized within a Crew.

### Outing Data

- Title
- Description
- Date
- Time
- Location
- Participants
- Chat
- Votes
- Status

---

# Domain Model

```text
User
 ├── CrewMemberships
 ├── CrewInvitations
 └── OutingParticipations

Crew
 ├── Owner
 ├── Members
 ├── Invitations
 └── Outings

Outing
 ├── Participants
 ├── Votes
 ├── Chat
 ├── Location
 └── Status Updates

Vote
 ├── Time Proposal
 └── Location Proposal

Chat
 └── Messages

LiveStatus
 ├── Getting Ready
 ├── On My Way
 └── Arrived
```

---

# Authentication Strategy

Authentication is handled exclusively through Firebase Authentication.

Supported providers:

- Google Sign-In
- Sign in with Apple

Email and password authentication is not supported.

### First Login Flow

1. User signs in using Google or Apple.
2. Application creates the user record.
3. User chooses:
   - Display Name
   - Unique Username
4. User enters the application.

### Username Rules

- Must be unique.
- Used for Crew invitations.
- Can be searched by other users.
- Cannot contain spaces.
- Case-insensitive uniqueness.

---

# User Onboarding Flow

```text
Launch App
    ↓
Google / Apple Sign-In
    ↓
Create Username
    ↓
Create Display Name
    ↓
Dashboard
```

---

# Outing Lifecycle

```text
Draft
  ↓
Planning
  ↓
Confirmed
  ↓
Meeting
  ↓
Completed
  ↓
Archived
```

### Draft

Initial outing creation.

### Planning

Members discuss and vote.

### Confirmed

Final location and time selected.

### Meeting

Members are preparing, travelling, or arriving.

### Completed

Outing finished.

### Archived

Historical record retained.

---

# User Status Lifecycle

```text
Invited
 ↓
Accepted
 ↓
Getting Ready
 ↓
On My Way
 ↓
Arrived
```

Or:

```text
Invited
 ↓
Declined
```

---

# Supported Platforms

## Mobile

- Android
- iOS

## Desktop

- Windows

## Web

- Modern Browsers

The application is developed using a single Flutter codebase.

---

# Technology Stack

## Frontend

- Flutter

## State Management

- flutter_bloc
- Cubit
- BlocObserver

---

## Architecture Style

Feature-First + Clean Architecture

```text
lib/
│
├── core/
│
├── features/
│   ├── authentication/
│   ├── profile/
│   ├── crews/
│   ├── outings/
│   ├── voting/
│   ├── chat/
│   ├── live_meetup/
│   └── notifications/
│
└── app/
```

### Feature Structure

```text
feature/
├── data/
├── domain/
└── presentation/
```

---

# Firebase Services

## Firebase Authentication

Used for:

- Registration
- Login
- User identity management

Providers:

- Google Sign-In
- Sign in with Apple

---

## Cloud Firestore

Primary database.

Used for:

- Users
- Crews
- Crew Memberships
- Crew Invitations
- Outings
- Participants
- Votes

---

## Firebase Cloud Messaging (FCM)

Used for:

- Crew invitations
- Outing invitations
- Voting updates
- Status updates
- Arrival notifications

---

## Cloud Functions

Used for:

- Notification triggers
- Scheduled cleanup
- Business rules
- Permission validation

---

## Firebase Storage

Used for:

- User avatars

---

## Firebase Analytics

Used for:

- User activity tracking
- Feature usage metrics

---

## Firebase Crashlytics

Used for:

- Error monitoring
- Production debugging

---

# Maps Strategy

The application should abstract map providers behind a common interface.

Initial implementation:

- Google Maps

Features:

- Location selection
- Meetup location display
- Live meetup map

---

# Database Strategy

## Persistent Data

Collections:

- users
- crews
- crew_memberships
- crew_invitations
- outings
- outing_participants
- votes

---

## Temporary Data

Collections:

- chat_messages
- live_locations
- presence_data

Retention Rules:

- Chat expires after 24 hours.
- Live location data is removed after outing completion.

---

# MVP Scope

The first release focuses on solving the core problem of organizing outings.

Included:

- Authentication
- User Profiles
- Crews
- Outings
- Voting
- Chat
- Live Status
- Notifications

---

# Roadmap (Spec-Kit Phases)

## Phase 0 — Architecture & Multi-Platform Setup

### Goal

Build a scalable Flutter architecture supporting Android, iOS, Web and Windows using Firebase.

### Features

#### Project Foundation

- Flutter project setup
- Feature-first architecture
- Clean Architecture
- Dependency injection
- Routing architecture
- Design system
- Responsive layout foundation

#### Firebase Setup

- Firebase project configuration
- FlutterFire integration
- Firestore configuration
- FCM configuration
- Crashlytics configuration

#### Multi-Platform Support

- Android setup
- iOS setup
- Web setup
- Windows setup

#### Data Layer

- Repository pattern
- Firestore models
- Domain entities
- DTO mapping strategy

#### Quality Foundation

- Error handling
- Logging
- Analytics integration

### Deliverable

Production-ready Flutter foundation for all target platforms.

---

## Phase 1 — Authentication & Profiles

### Goal

Allow users to create and manage accounts.

### Features

- Google Sign-In
- Sign in with Apple
- Username creation
- Username validation
- Profile management
- Avatar support
- Session persistence

### Deliverable

Users can create accounts and manage profiles.

---

## Phase 2 — Crew Management

### Goal

Allow users to organize themselves into Crews.

### Features

- Create Crew
- Edit Crew
- Delete Crew
- Invite members by username
- Accept invitation
- Reject invitation
- Leave Crew
- Remove members
- Crew details
- Member list

### Deliverable

Users can create and manage Crews.

---

## Phase 3 — Outing Management

### Goal

Allow Crews to create and manage outings.

### Features

- Create outing
- Edit outing
- Cancel outing
- Outing details
- Participant management
- Outing lifecycle management

### Deliverable

Crews can organize outings.

---

## Phase 4 — Agreement System

### Goal

Help members reach decisions collaboratively.

### Features

- Accept outing
- Decline outing
- Suggest time
- Suggest location
- Voting system
- Final confirmation

### Deliverable

Members can agree on outing details.

---

## Phase 5 — Outing Chat

### Goal

Provide outing-specific communication.

### Features

- Dedicated outing chat
- Message history
- Read status
- Temporary chat lifecycle
- Automatic cleanup

### Deliverable

Every outing has its own communication channel.

---

## Phase 6 — Live Meetup

### Goal

Support real-world coordination during the outing.

### Features

- Getting Ready status
- On My Way status
- Arrived status
- Live location sharing
- Shared meetup map

### Deliverable

Members can coordinate arrivals in real time.

---

## Phase 7 — Notifications

### Goal

Keep users informed of important updates.

### Features

- Crew invitations
- Outing invitations
- Voting updates
- Outing changes
- Arrival notifications
- Push notifications

### Deliverable

Users receive real-time updates.

---

## Phase 8 — Production Readiness

### Goal

Prepare the MVP for public release.

### Features

- Unit testing
- Widget testing
- Integration testing
- Firestore security rules
- Performance optimization
- Analytics review
- Crash monitoring
- Store release preparation

### Deliverable

Production-ready MVP.

---

# Success Criteria

The MVP is considered successful when users can:

1. Create a Crew.
2. Invite members.
3. Create an Outing.
4. Vote on decisions.
5. Coordinate attendance.
6. Meet successfully.
7. Complete the outing without relying on external chat applications.