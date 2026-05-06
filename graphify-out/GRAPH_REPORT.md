# Graph Report - tfg_frontend  (2026-05-06)

## Corpus Check
- 132 files · ~86,740 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 694 nodes · 1026 edges · 59 communities detected
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 54 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b7dc889d`
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
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]
- [[_COMMUNITY_Community 90|Community 90]]
- [[_COMMUNITY_Community 91|Community 91]]
- [[_COMMUNITY_Community 92|Community 92]]
- [[_COMMUNITY_Community 93|Community 93]]
- [[_COMMUNITY_Community 94|Community 94]]
- [[_COMMUNITY_Community 95|Community 95]]

## God Nodes (most connected - your core abstractions)
1. `package:tfg_frontend/features/auth/data/models/auth_models.dart` - 41 edges
2. `package:flutter_test/flutter_test.dart` - 37 edges
3. `package:mocktail/mocktail.dart` - 27 edges
4. `package:tfg_frontend/core/storage/token_storage.dart` - 23 edges
5. `package:flutter/material.dart` - 22 edges
6. `package:provider/provider.dart` - 22 edges
7. `package:http/http.dart` - 20 edges
8. `dart:convert` - 17 edges
9. `package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart` - 11 edges
10. `ClassSessionProvider` - 11 edges

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

## Communities (96 total, 21 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (57): dart:convert, AuthRepository, ApiException, BookingRepository, ClassSessionRepository, GymRepository, ApiException, MembershipPlanRepository (+49 more)

### Community 1 - "Community 1"
Cohesion: 0.06
Nodes (61): API Error Envelope, ApiException / Auth Models, Bottom Navigation Bar (4 tabs), ClassSession, ClassSession Models, ClassSession Models Test, ClassSessionPage, ClassSessionProvider (+53 more)

### Community 2 - "Community 2"
Cohesion: 0.06
Nodes (32): dart:async, dispose, GymListProvider, query, ProfileProvider, build, Card, Container (+24 more)

### Community 3 - "Community 3"
Cohesion: 0.09
Nodes (37): ApiException, AuthResponse, AuthTokens, AuthUser, UserRole, AuthProvider, AuthStatus, AuthRepository (+29 more)

### Community 4 - "Community 4"
Cohesion: 0.11
Nodes (19): RegisterPlugins(), FlutterWindow(), OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle() (+11 more)

### Community 5 - "Community 5"
Cohesion: 0.08
Nodes (23): StatsProvider, build, Card, _DetailRow, Icon, initState, Padding, SingleChildScrollView (+15 more)

### Community 6 - "Community 6"
Cohesion: 0.1
Nodes (19): _BookButton, build, Card, Center, ClassesScreen, _ClassesScreenState, Container, dispose (+11 more)

### Community 7 - "Community 7"
Cohesion: 0.11
Nodes (18): _browseGyms, build, Card, Center, Container, Divider, _EmptyState, Function (+10 more)

### Community 8 - "Community 8"
Cohesion: 0.11
Nodes (17): _BookingCard, build, Card, Center, Container, dispose, _formatStartTime, Icon (+9 more)

### Community 9 - "Community 9"
Cohesion: 0.12
Nodes (15): build, Card, _clearSearch, dispose, Function, _GymCard, GymListScreen, _GymListScreenState (+7 more)

### Community 10 - "Community 10"
Cohesion: 0.12
Nodes (13): main, ApiException, main, MockSubscriptionRepository, ApiException, _buildSubject, main, MockSubscriptionRepository (+5 more)

### Community 11 - "Community 11"
Cohesion: 0.13
Nodes (14): App, _AuthGate, _AuthGateState, build, gymListScreenBuilder, gymPlansProviderBuilder, _HomeShell, LoginScreen (+6 more)

### Community 12 - "Community 12"
Cohesion: 0.14
Nodes (4): fl_register_plugins(), main(), my_application_activate(), my_application_new()

### Community 13 - "Community 13"
Cohesion: 0.15
Nodes (11): BookingProvider, main, ApiException, _buildSubject, ChangeNotifierProvider, main, _makePage, MockBookingRepository (+3 more)

### Community 14 - "Community 14"
Cohesion: 0.15
Nodes (12): ApiException, _buildSubject, ChangeNotifierProvider, _gymPlansProviderBuilder, main, MockGymRepository, MockMembershipPlanRepository, MockSubscriptionRepository (+4 more)

### Community 15 - "Community 15"
Cohesion: 0.17
Nodes (11): build, Card, _Chip, Container, GymPlansScreen, _GymPlansScreenState, initState, _PlanCard (+3 more)

### Community 16 - "Community 16"
Cohesion: 0.18
Nodes (9): ClassSessionProvider, main, main, _makePage, _makeSession, MockClassSessionRepository, package:tfg_frontend/features/classes/data/models/class_session_models.dart, package:tfg_frontend/features/classes/data/repositories/class_session_repository.dart (+1 more)

### Community 17 - "Community 17"
Cohesion: 0.2
Nodes (8): GymPlansProvider, loadMySubscriptions, SubscriptionProvider, main, package:tfg_frontend/core/models/subscription.dart, package:tfg_frontend/features/membership_plans/data/repositories/membership_plan_repository.dart, package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart, package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart

### Community 18 - "Community 18"
Cohesion: 0.2
Nodes (9): ApiException, _buildSubject, _buildWithParent, ChangeNotifierProvider, main, MaterialApp, MockMembershipPlanRepository, MockSubscriptionRepository (+1 more)

### Community 19 - "Community 19"
Cohesion: 0.22
Nodes (3): FlutterAppDelegate, FlutterImplicitEngineDelegate, AppDelegate

### Community 20 - "Community 20"
Cohesion: 0.22
Nodes (7): main, ApiException, main, MockGymRepository, package:fake_async/fake_async.dart, package:tfg_frontend/features/gyms/data/models/gym_models.dart, package:tfg_frontend/features/gyms/presentation/providers/gym_list_provider.dart

### Community 21 - "Community 21"
Cohesion: 0.22
Nodes (7): main, ApiException, main, MockMembershipPlanRepository, MockSubscriptionRepository, package:tfg_frontend/features/membership_plans/data/models/membership_plan_models.dart, package:tfg_frontend/features/membership_plans/presentation/providers/gym_plans_provider.dart

### Community 22 - "Community 22"
Cohesion: 0.22
Nodes (8): build, Center, HomeShell, HomeShellState, HomeTab, PopScope, SizedBox, package:tfg_frontend/features/classes/presentation/screens/classes_screen.dart

### Community 23 - "Community 23"
Cohesion: 0.25
Nodes (7): ApiException, AuthResponse, AuthTokens, AuthUser, fromString, toJson, toString

### Community 24 - "Community 24"
Cohesion: 0.25
Nodes (7): build, dispose, Scaffold, SignupScreen, _SignupScreenState, SizedBox, SnackBar

### Community 25 - "Community 25"
Cohesion: 0.25
Nodes (7): main, MockTokenStorage, MultiProvider, _wrap, wrapTab, package:flutter/services.dart, package:tfg_frontend/shell/home_shell.dart

### Community 26 - "Community 26"
Cohesion: 0.25
Nodes (7): ApiException, _buildSubject, ChangeNotifierProvider, _fakeAuthResponse, main, MockAuthRepository, package:tfg_frontend/features/auth/presentation/providers/auth_provider.dart

### Community 27 - "Community 27"
Cohesion: 0.25
Nodes (7): ApiException, _buildSubject, ChangeNotifierProvider, _fakeAuthResponse, main, MockAuthRepository, package:tfg_frontend/features/auth/presentation/screens/signup_screen.dart

### Community 28 - "Community 28"
Cohesion: 0.25
Nodes (7): build, dispose, LoginScreen, _LoginScreenState, Scaffold, SizedBox, SnackBar

### Community 29 - "Community 29"
Cohesion: 0.25
Nodes (7): Booking, BookingClassSession, BookingClassType, BookingGym, BookingPage, fromString, toJson

### Community 30 - "Community 30"
Cohesion: 0.25
Nodes (7): ApiException, main, _makePage, _makeSession, MockBookingRepository, MockClassSessionRepository, _wrap

### Community 31 - "Community 31"
Cohesion: 0.25
Nodes (7): ClassSession, ClassSessionPage, fromString, SessionClassType, SessionGym, SessionInstructor, toJson

### Community 32 - "Community 32"
Cohesion: 0.29
Nodes (6): main, MockAuthRepository, _noop, Scaffold, package:provider/provider.dart, package:tfg_frontend/features/auth/presentation/screens/login_screen.dart

### Community 33 - "Community 33"
Cohesion: 0.47
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 34 - "Community 34"
Cohesion: 0.33
Nodes (3): RegisterGeneratedPlugins(), NSWindow, MainFlutterWindow

### Community 35 - "Community 35"
Cohesion: 0.33
Nodes (5): ApiException, main, _makePage, MockBookingRepository, package:tfg_frontend/features/bookings/presentation/providers/booking_provider.dart

### Community 37 - "Community 37"
Cohesion: 0.4
Nodes (5): fromString, Subscription, SubscriptionGym, SubscriptionPlan, subscription_models.dart

### Community 38 - "Community 38"
Cohesion: 0.5
Nodes (3): AuthProvider, clearError, package:tfg_frontend/features/auth/data/repositories/auth_repository.dart

## Knowledge Gaps
- **374 isolated node(s):** `MainActivity`, `XCTestCase`, `NSWindow`, `FlutterAppDelegate`, `App` (+369 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **21 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 2` to `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 13`, `Community 14`, `Community 15`, `Community 18`, `Community 22`, `Community 24`, `Community 25`, `Community 26`, `Community 27`, `Community 28`, `Community 30`, `Community 32`?**
  _High betweenness centrality (0.070) - this node is a cross-community bridge._
- **Why does `package:provider/provider.dart` connect `Community 32` to `Community 2`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 13`, `Community 14`, `Community 15`, `Community 18`, `Community 22`, `Community 24`, `Community 25`, `Community 26`, `Community 27`, `Community 28`, `Community 30`?**
  _High betweenness centrality (0.070) - this node is a cross-community bridge._
- **Why does `package:tfg_frontend/features/auth/data/models/auth_models.dart` connect `Community 0` to `Community 32`, `Community 2`, `Community 35`, `Community 5`, `Community 38`, `Community 10`, `Community 13`, `Community 14`, `Community 16`, `Community 17`, `Community 18`, `Community 20`, `Community 21`, `Community 26`, `Community 27`, `Community 30`?**
  _High betweenness centrality (0.057) - this node is a cross-community bridge._
- **What connects `MainActivity`, `XCTestCase`, `NSWindow` to the rest of the system?**
  _374 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._