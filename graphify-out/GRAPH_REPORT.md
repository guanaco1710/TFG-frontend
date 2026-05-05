# Graph Report - tfg_frontend  (2026-05-05)

## Corpus Check
- 120 files · ~80,479 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 618 nodes · 895 edges · 47 communities detected
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 54 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `864a67b0`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 78|Community 78]]
- [[_COMMUNITY_Community 79|Community 79]]
- [[_COMMUNITY_Community 80|Community 80]]
- [[_COMMUNITY_Community 81|Community 81]]
- [[_COMMUNITY_Community 82|Community 82]]
- [[_COMMUNITY_Community 83|Community 83]]

## God Nodes (most connected - your core abstractions)
1. `package:tfg_frontend/features/auth/data/models/auth_models.dart` - 38 edges
2. `package:flutter_test/flutter_test.dart` - 31 edges
3. `package:mocktail/mocktail.dart` - 24 edges
4. `package:tfg_frontend/core/storage/token_storage.dart` - 21 edges
5. `package:flutter/material.dart` - 20 edges
6. `package:provider/provider.dart` - 20 edges
7. `package:http/http.dart` - 18 edges
8. `dart:convert` - 15 edges
9. `ClassSessionProvider` - 11 edges
10. `package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart` - 10 edges

## Surprising Connections (you probably didn't know these)
- `API Error Envelope` --rationale_for--> `ApiException / Auth Models`  [INFERRED]
  docs/endpoints.md → lib/features/auth/data/models/auth_models.dart
- `JWT Bearer Token Auth Pattern` --rationale_for--> `TokenStorage`  [INFERRED]
  docs/REQUIREMENTS.md → lib/core/storage/token_storage.dart
- `Known Issue: startTime lacks timezone` --conceptually_related_to--> `ClassSession Models`  [EXTRACTED]
  docs/endpoints.md → lib/features/classes/data/models/class_session_models.dart
- `Provider + ChangeNotifier MVVM Pattern` --rationale_for--> `GymPlansProvider`  [INFERRED]
  test/features/profile/presentation/profile_provider_test.dart → lib/features/membership_plans/presentation/providers/gym_plans_provider.dart
- `gym_list_screen_test` --references--> `GymPlansScreen`  [EXTRACTED]
  test/features/gyms/gym_list_screen_test.dart → lib/features/membership_plans/presentation/screens/gym_plans_screen.dart

## Hyperedges (group relationships)
- **Auth Flow and Session Management** — auth_repository_authrepository, auth_provider_authprovider, main_authgate [EXTRACTED 1.00]
- **Repository-Provider-Screen Feature Pattern** — subscription_repository_subscriptionrepository, subscription_provider_subscriptionprovider, my_subscription_screen_mysubscriptionscreen [INFERRED 0.95]
- **Shared ApiException Error Handling across Repositories** — auth_models_apiexception, subscription_repository_subscriptionrepository, gym_repository_gymrepository, user_repository_userrepository, stats_repository_statsrepository [EXTRACTED 1.00]
- **ClassSession Data Flow: Repository to Provider to Screen** — class_session_repository, class_session_provider, classes_screen [EXTRACTED 0.95]
- **MembershipPlan Data Flow: Repository to Provider to Screen** — membership_plan_repository, gym_plans_provider, gym_plans_screen [EXTRACTED 0.95]
- **HomeShell Bottom-Nav Tab Composition** — home_shell, classes_screen, home_tab [EXTRACTED 0.95]
- **Feature Layer Stack: Repository to Provider to Screen** — class_session_repository, class_session_provider, classes_screen [INFERRED 0.95]
- **GymPlansProvider Aggregates MembershipPlan and Subscription Repos** — gym_plans_provider, membership_plan_repository, subscription_repository [EXTRACTED 1.00]
- **HomeShell NavigationBar Tabs** — home_shell, classes_screen, stats_screen, profile_screen [INFERRED 0.95]

## Communities (84 total, 21 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.06
Nodes (61): API Error Envelope, ApiException / Auth Models, Bottom Navigation Bar (4 tabs), ClassSession, ClassSession Models, ClassSession Models Test, ClassSessionPage, ClassSessionProvider (+53 more)

### Community 1 - "Community 1"
Cohesion: 0.06
Nodes (40): dart:convert, AuthRepository, ClassSessionRepository, ClassSessionProvider, GymRepository, ApiException, MembershipPlanRepository, StatsRepository (+32 more)

### Community 2 - "Community 2"
Cohesion: 0.05
Nodes (43): AuthProvider, clearError, StatsProvider, ApiException, _fakeAuthResponse, main, MockAuthRepository, ApiException (+35 more)

### Community 3 - "Community 3"
Cohesion: 0.05
Nodes (41): dart:async, dispose, GymListProvider, query, _browseGyms, build, Card, Center (+33 more)

### Community 4 - "Community 4"
Cohesion: 0.09
Nodes (37): ApiException, AuthResponse, AuthTokens, AuthUser, UserRole, AuthProvider, AuthStatus, AuthRepository (+29 more)

### Community 5 - "Community 5"
Cohesion: 0.06
Nodes (31): build, Card, Center, ClassesScreen, _ClassesScreenState, Container, dispose, Divider (+23 more)

### Community 6 - "Community 6"
Cohesion: 0.07
Nodes (27): UserRepository, ProfileProvider, build, Card, Container, Divider, Icon, _InfoCard (+19 more)

### Community 7 - "Community 7"
Cohesion: 0.11
Nodes (19): RegisterPlugins(), FlutterWindow(), OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle() (+11 more)

### Community 8 - "Community 8"
Cohesion: 0.12
Nodes (15): build, Center, HomeShell, HomeShellState, HomeTab, PopScope, SizedBox, ApiException (+7 more)

### Community 9 - "Community 9"
Cohesion: 0.13
Nodes (14): build, Card, _clearSearch, dispose, _GymCard, GymListScreen, _GymListScreenState, Icon (+6 more)

### Community 10 - "Community 10"
Cohesion: 0.14
Nodes (4): fl_register_plugins(), main(), my_application_activate(), my_application_new()

### Community 11 - "Community 11"
Cohesion: 0.15
Nodes (12): build, Card, _DetailRow, Icon, initState, Padding, SingleChildScrollView, SizedBox (+4 more)

### Community 12 - "Community 12"
Cohesion: 0.17
Nodes (11): build, Card, _Chip, Container, GymPlansScreen, _GymPlansScreenState, initState, _PlanCard (+3 more)

### Community 13 - "Community 13"
Cohesion: 0.18
Nodes (10): App, _AuthGate, _AuthGateState, build, HomeShell, LoginScreen, main, MultiProvider (+2 more)

### Community 14 - "Community 14"
Cohesion: 0.2
Nodes (9): ApiException, _buildSubject, _buildWithParent, ChangeNotifierProvider, main, MaterialApp, MockMembershipPlanRepository, MockSubscriptionRepository (+1 more)

### Community 15 - "Community 15"
Cohesion: 0.22
Nodes (7): GymPlansProvider, loadMySubscriptions, SubscriptionProvider, main, package:tfg_frontend/features/membership_plans/data/repositories/membership_plan_repository.dart, package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart, package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart

### Community 16 - "Community 16"
Cohesion: 0.22
Nodes (3): FlutterAppDelegate, FlutterImplicitEngineDelegate, AppDelegate

### Community 17 - "Community 17"
Cohesion: 0.22
Nodes (8): build, dispose, Scaffold, SignupScreen, _SignupScreenState, SizedBox, SnackBar, package:provider/provider.dart

### Community 18 - "Community 18"
Cohesion: 0.22
Nodes (8): build, dispose, LoginScreen, _LoginScreenState, Scaffold, SizedBox, SnackBar, package:flutter/material.dart

### Community 19 - "Community 19"
Cohesion: 0.25
Nodes (7): ApiException, AuthResponse, AuthTokens, AuthUser, fromString, toJson, toString

### Community 20 - "Community 20"
Cohesion: 0.25
Nodes (7): main, MockTokenStorage, MultiProvider, _wrap, wrapTab, package:flutter/services.dart, package:tfg_frontend/shell/home_shell.dart

### Community 21 - "Community 21"
Cohesion: 0.25
Nodes (7): ClassSession, ClassSessionPage, fromString, SessionClassType, SessionGym, SessionInstructor, toJson

### Community 22 - "Community 22"
Cohesion: 0.47
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 23 - "Community 23"
Cohesion: 0.33
Nodes (3): RegisterGeneratedPlugins(), NSWindow, MainFlutterWindow

### Community 24 - "Community 24"
Cohesion: 0.33
Nodes (5): ApiException, main, MockMembershipPlanRepository, MockSubscriptionRepository, package:tfg_frontend/features/membership_plans/presentation/providers/gym_plans_provider.dart

### Community 26 - "Community 26"
Cohesion: 0.4
Nodes (4): fromString, Subscription, SubscriptionGym, SubscriptionPlan

## Knowledge Gaps
- **315 isolated node(s):** `MainActivity`, `XCTestCase`, `NSWindow`, `FlutterAppDelegate`, `App` (+310 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **21 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 18` to `Community 2`, `Community 3`, `Community 5`, `Community 6`, `Community 8`, `Community 9`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 17`, `Community 20`?**
  _High betweenness centrality (0.064) - this node is a cross-community bridge._
- **Why does `package:provider/provider.dart` connect `Community 17` to `Community 2`, `Community 3`, `Community 5`, `Community 6`, `Community 8`, `Community 9`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 18`, `Community 20`?**
  _High betweenness centrality (0.064) - this node is a cross-community bridge._
- **Why does `package:tfg_frontend/features/auth/data/models/auth_models.dart` connect `Community 1` to `Community 2`, `Community 3`, `Community 5`, `Community 6`, `Community 8`, `Community 14`, `Community 15`, `Community 24`?**
  _High betweenness centrality (0.057) - this node is a cross-community bridge._
- **What connects `MainActivity`, `XCTestCase`, `NSWindow` to the rest of the system?**
  _315 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._