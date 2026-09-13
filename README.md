# GameHub — Salesforce Gaming Management System

## 🚀 Live App & Org Links
- **Direct App Link**: [Launch GameHub Console Home](https://orgfarm-b6f0401ced-dev-ed.develop.my.salesforce.com/lightning/n/GameHub_Console_Home)
- **Salesforce Org URL**: [Salesforce Developer Org](https://orgfarm-b6f0401ced-dev-ed.develop.my.salesforce.com)

A Salesforce DX project implementing GameHub's tournament/leaderboard/rewards platform,
built from the architecture spec (Player registrations, game catalog, tournaments,
match results, leaderboards, rewards) using custom objects, Apex, triggers, a batch job,
and Lightning Web Components.

## Project layout

```
force-app/main/default/
├── objects/                # 7 custom objects (see Data Model below)
├── classes/                # Apex controllers + batch job + tests
├── triggers/                # MatchTrigger, TournamentTrigger
├── lwc/                     # playerDashboard, gameCatalog, tournamentList,
│                             matchManager, leaderBoard, rewardPanel
├── permissionsets/          # GameHub_Player, GameHub_Admin
├── applications/            # GameHub Console (Lightning App)
├── tabs/                    # Custom object tabs
├── flexipages/              # GameHub Console Home page
├── reports/, dashboards/    # Empty folders — see "Reports & Dashboards" below
manifest/package.xml         # Metadata manifest for a manual `sf project deploy`
```

## Data model

| Object | Purpose | Key relationships |
|---|---|---|
| `Player__c` | Player profile, score, rank | — |
| `Game__c` | Game catalog | — |
| `Tournament__c` | Tournaments | Lookup → `Game__c` |
| `Tournament_Registration__c` | Player ↔ Tournament join | Lookup → `Player__c`, `Tournament__c` |
| `Match__c` | Individual matches | Lookup → `Tournament__c`, `Game__c`, `Player__c` (Winner) |
| `Match_Player__c` | Match participants (junction) | Master-Detail → `Match__c`, Lookup → `Player__c` |
| `Reward__c` | Achievements/rewards | Lookup → `Player__c`, `Tournament__c` |

## Automation

- **MatchTrigger** (`after update` on `Match__c`): when a match flips to `Completed`,
  rolls each participant's `Match_Player__c.Score__c` into `Player__c.Total_Score__c`.
- **TournamentTrigger** (`after update` on `Tournament__c`): when a tournament flips to
  `Completed`, marks the top-scoring registration `Winner` and issues a Trophy `Reward__c`.
- **LeaderboardBatch**: batchable class intended to run nightly (schedule it via
  `System.schedule` or Setup → Scheduled Jobs) — recalculates every player's `Rank__c`
  and logs a Top 100 snapshot.

## Apex classes

- `PlayerController` — player profile, recent matches, rewards, score updates
- `GameController` — game catalog with category filter
- `TournamentController` — browse tournaments, join tournament (capacity + duplicate checks)
- `MatchController` — admin: create match, assign players, update scores, declare winner
- `LeaderboardController` — top players, tournament ranking, on-demand rank recalculation
- `LeaderboardBatch` — scheduled batch job for nightly rank recalculation

All controllers use `with sharing` and `WITH SECURITY_ENFORCED` / field-level security
appropriate checks. Each has a companion `*Test` class targeting >75% coverage.

## Lightning Web Components

| Component | Role |
|---|---|
| `playerDashboard` | Player profile, score, rank, recent matches, rewards |
| `gameCatalog` | Browse/filter games, view tournaments for a game |
| `tournamentList` | Browse active tournaments, join a tournament |
| `matchManager` | **Admin**: create matches, assign players, update scores, declare winners |
| `leaderBoard` | Global + tournament leaderboards, on-demand recalculation |
| `rewardPanel` | Player's earned rewards/badges |

## Security model

- `GameHub_Player` permission set: read on Games/Tournaments/Matches, create/read on
  own Player/Tournament_Registration records — matches the spec's private sharing
  model for Player/Rewards and public read for Games/Tournaments.
- `GameHub_Admin` permission set: full CRUD + view/modify all on every GameHub object.
- Assign these via Setup → Permission Sets rather than editing the Standard User profile.

## Reports & Dashboards

Empty `reports/` and `dashboards/` folders are scaffolded, but report/dashboard
metadata is dependent on org-specific Report Types and is easiest to get right by
building these directly in Setup → Reports once the objects are deployed:

- **Reports**: Top Players, Tournament Participation, Game Popularity, Reward Distribution
- **Dashboard**: "Gaming Analytics Dashboard" with widgets for active tournaments,
  top 10 players, game popularity, and monthly matches.

## Deploying

Requires the [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli).

```bash
# Authenticate to your org
sf org login web --alias gamehub-org

# Deploy everything
sf project deploy start --target-org gamehub-org

# Run Apex tests
sf apex run test --target-org gamehub-org --code-coverage --result-format human

# Assign yourself a permission set
sf org assign permset --name GameHub_Admin --target-org gamehub-org
```

Or deploy from the manifest:

```bash
sf project deploy start --manifest manifest/package.xml --target-org gamehub-org
```

## Post-deploy setup checklist

1. Assign `GameHub_Admin` / `GameHub_Player` permission sets to the relevant users.
2. Schedule `LeaderboardBatch` to run nightly (Setup → Apex Classes → Schedule Apex, or
   `System.schedule('GameHub Leaderboard Batch', '0 0 2 * * ?', new LeaderboardBatch());`).
3. Build the Reports/Dashboard listed above.
4. If exposing the player experience externally, enable an Experience Cloud site and
   add `playerDashboard`, `gameCatalog`, `tournamentList`, and `rewardPanel` to its pages.
5. Add the `GameHub Console` app to relevant App Launcher visibility / profiles.
