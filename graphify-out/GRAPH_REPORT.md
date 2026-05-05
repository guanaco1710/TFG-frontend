# Graph Report - .  (2026-05-05)

## Corpus Check
- 67 files · ~31,146 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 487 nodes · 794 edges · 42 communities detected
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 46 edges (avg confidence: 0.89)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Data Repositories & HTTP|Data Repositories & HTTP]]
- [[_COMMUNITY_API Contracts & Session Models|API Contracts & Session Models]]
- [[_COMMUNITY_Gym Browse UI Widgets|Gym Browse UI Widgets]]
- [[_COMMUNITY_Classes Screen & Provider|Classes Screen & Provider]]
- [[_COMMUNITY_Auth Domain Model|Auth Domain Model]]
- [[_COMMUNITY_Async Providers & State|Async Providers & State]]
- [[_COMMUNITY_App Shell & Navigation|App Shell & Navigation]]
- [[_COMMUNITY_Info Card Components|Info Card Components]]
- [[_COMMUNITY_Gym List Screen|Gym List Screen]]
- [[_COMMUNITY_Profile Feature MVVM|Profile Feature MVVM]]
- [[_COMMUNITY_Membership Plans Screen|Membership Plans Screen]]
- [[_COMMUNITY_App Bootstrap & Auth Gate|App Bootstrap & Auth Gate]]
- [[_COMMUNITY_App Entry & Provider Setup|App Entry & Provider Setup]]
- [[_COMMUNITY_Subscription & Plans Providers|Subscription & Plans Providers]]
- [[_COMMUNITY_Login Screen|Login Screen]]
- [[_COMMUNITY_Subscription Plan Tests|Subscription Plan Tests]]
- [[_COMMUNITY_Auth Serialization Models|Auth Serialization Models]]
- [[_COMMUNITY_Signup Screen|Signup Screen]]
- [[_COMMUNITY_Auth Provider Tests|Auth Provider Tests]]
- [[_COMMUNITY_Auth Screen Tests|Auth Screen Tests]]
- [[_COMMUNITY_Subscription Screen Tests|Subscription Screen Tests]]
- [[_COMMUNITY_Class Session Models|Class Session Models]]
- [[_COMMUNITY_Smoke Test Setup|Smoke Test Setup]]
- [[_COMMUNITY_Auth Provider Test Suite|Auth Provider Test Suite]]
- [[_COMMUNITY_Model Unit Tests|Model Unit Tests]]
- [[_COMMUNITY_Subscription Models|Subscription Models]]
- [[_COMMUNITY_Subscription Provider Tests|Subscription Provider Tests]]
- [[_COMMUNITY_Auth Provider|Auth Provider]]
- [[_COMMUNITY_Gym Models|Gym Models]]
- [[_COMMUNITY_User Profile Model|User Profile Model]]
- [[_COMMUNITY_User Stats Model|User Stats Model]]
- [[_COMMUNITY_Membership Plan Model|Membership Plan Model]]
- [[_COMMUNITY_Provider Test Pair|Provider Test Pair]]
- [[_COMMUNITY_Repository Test Pair|Repository Test Pair]]
- [[_COMMUNITY_Gym Test Pair|Gym Test Pair]]
- [[_COMMUNITY_App Branding|App Branding]]
- [[_COMMUNITY_Widget Smoke Test|Widget Smoke Test]]
- [[_COMMUNITY_Auth Models Test|Auth Models Test]]
- [[_COMMUNITY_Signup Screen Test|Signup Screen Test]]
- [[_COMMUNITY_Login Screen Test|Login Screen Test]]
- [[_COMMUNITY_Subscription Screen Test|Subscription Screen Test]]
- [[_COMMUNITY_Subscription Models Test|Subscription Models Test]]

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
- `Provider + ChangeNotifier MVVM Pattern` --rationale_for--> `ClassSessionProvider`  [INFERRED]
  test/features/profile/presentation/profile_provider_test.dart → lib/features/classes/presentation/providers/class_session_provider.dart

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

## Communities (42 total, 14 thin omitted)

### Community 0 - "Data Repositories & HTTP"
Cohesion: 0.06
Nodes (39): dart:convert, AuthRepository, ClassSessionRepository, GymRepository, ApiException, MembershipPlanRepository, UserRepository, StatsRepository (+31 more)

### Community 1 - "API Contracts & Session Models"
Cohesion: 0.08
Nodes (46): API Error Envelope, ApiException / Auth Models, Bottom Navigation Bar (4 tabs), ClassSession, ClassSession Models, ClassSession Models Test, ClassSessionPage, ClassSessionProvider (+38 more)

### Community 2 - "Gym Browse UI Widgets"
Cohesion: 0.06
Nodes (35): _browseGyms, build, Card, Center, Container, Divider, _EmptyState, _InfoRow (+27 more)

### Community 3 - "Classes Screen & Provider"
Cohesion: 0.06
Nodes (33): ClassSessionProvider, build, Card, Center, ClassesScreen, _ClassesScreenState, Container, dispose (+25 more)

### Community 4 - "Auth Domain Model"
Cohesion: 0.09
Nodes (37): ApiException, AuthResponse, AuthTokens, AuthUser, UserRole, AuthProvider, AuthStatus, AuthRepository (+29 more)

### Community 5 - "Async Providers & State"
Cohesion: 0.07
Nodes (28): dart:async, dispose, GymListProvider, query, StatsProvider, build, Card, _DetailRow (+20 more)

### Community 6 - "App Shell & Navigation"
Cohesion: 0.08
Nodes (25): ProfileProvider, build, Center, HomeShell, HomeShellState, HomeTab, PopScope, SizedBox (+17 more)

### Community 7 - "Info Card Components"
Cohesion: 0.12
Nodes (15): build, Card, Container, Divider, Icon, _InfoCard, _InfoRow, initState (+7 more)

### Community 8 - "Gym List Screen"
Cohesion: 0.13
Nodes (14): build, Card, _clearSearch, dispose, _GymCard, GymListScreen, _GymListScreenState, Icon (+6 more)

### Community 9 - "Profile Feature MVVM"
Cohesion: 0.25
Nodes (15): ProfileProvider, ProfileProvider Test, ProfileScreen, ProfileScreen Widget Test, Provider + ChangeNotifier MVVM Pattern, UserStats Model, UserStats Models Test, StatsProvider (+7 more)

### Community 10 - "Membership Plans Screen"
Cohesion: 0.17
Nodes (11): build, Card, _Chip, Container, GymPlansScreen, _GymPlansScreenState, initState, _PlanCard (+3 more)

### Community 11 - "App Bootstrap & Auth Gate"
Cohesion: 0.18
Nodes (10): App, _AuthGate, _AuthGateState, build, HomeShell, LoginScreen, main, MultiProvider (+2 more)

### Community 12 - "App Entry & Provider Setup"
Cohesion: 0.2
Nodes (9): ApiException, _buildSubject, _buildWithParent, ChangeNotifierProvider, main, MaterialApp, MockMembershipPlanRepository, MockSubscriptionRepository (+1 more)

### Community 13 - "Subscription & Plans Providers"
Cohesion: 0.22
Nodes (7): GymPlansProvider, loadMySubscriptions, SubscriptionProvider, main, package:tfg_frontend/features/membership_plans/data/repositories/membership_plan_repository.dart, package:tfg_frontend/features/subscriptions/data/models/subscription_models.dart, package:tfg_frontend/features/subscriptions/data/repositories/subscription_repository.dart

### Community 14 - "Login Screen"
Cohesion: 0.22
Nodes (8): build, dispose, LoginScreen, _LoginScreenState, Scaffold, SizedBox, SnackBar, package:provider/provider.dart

### Community 15 - "Subscription Plan Tests"
Cohesion: 0.22
Nodes (7): main, ApiException, main, MockMembershipPlanRepository, MockSubscriptionRepository, package:tfg_frontend/features/membership_plans/data/models/membership_plan_models.dart, package:tfg_frontend/features/membership_plans/presentation/providers/gym_plans_provider.dart

### Community 16 - "Auth Serialization Models"
Cohesion: 0.25
Nodes (7): ApiException, AuthResponse, AuthTokens, AuthUser, fromString, toJson, toString

### Community 17 - "Signup Screen"
Cohesion: 0.25
Nodes (7): build, dispose, Scaffold, SignupScreen, _SignupScreenState, SizedBox, SnackBar

### Community 18 - "Auth Provider Tests"
Cohesion: 0.25
Nodes (7): ApiException, _buildSubject, ChangeNotifierProvider, _fakeAuthResponse, main, MockAuthRepository, package:tfg_frontend/features/auth/presentation/screens/signup_screen.dart

### Community 19 - "Auth Screen Tests"
Cohesion: 0.25
Nodes (7): ApiException, _buildSubject, ChangeNotifierProvider, _fakeAuthResponse, main, MockAuthRepository, package:tfg_frontend/features/auth/presentation/screens/login_screen.dart

### Community 20 - "Subscription Screen Tests"
Cohesion: 0.25
Nodes (7): ApiException, _buildSubject, main, MockSubscriptionRepository, MockTokenStorage, MultiProvider, package:tfg_frontend/features/subscriptions/presentation/screens/my_subscription_screen.dart

### Community 21 - "Class Session Models"
Cohesion: 0.25
Nodes (7): ClassSession, ClassSessionPage, fromString, SessionClassType, SessionGym, SessionInstructor, toJson

### Community 22 - "Smoke Test Setup"
Cohesion: 0.33
Nodes (5): main, MockAuthRepository, _noop, Scaffold, package:flutter/material.dart

### Community 23 - "Auth Provider Test Suite"
Cohesion: 0.33
Nodes (5): ApiException, _fakeAuthResponse, main, MockAuthRepository, package:tfg_frontend/features/auth/presentation/providers/auth_provider.dart

### Community 24 - "Model Unit Tests"
Cohesion: 0.33
Nodes (4): main, main, package:flutter_test/flutter_test.dart, package:tfg_frontend/features/gyms/data/models/gym_models.dart

### Community 25 - "Subscription Models"
Cohesion: 0.4
Nodes (4): fromString, Subscription, SubscriptionGym, SubscriptionPlan

### Community 26 - "Subscription Provider Tests"
Cohesion: 0.4
Nodes (4): ApiException, main, MockSubscriptionRepository, package:tfg_frontend/features/subscriptions/presentation/providers/subscription_provider.dart

### Community 27 - "Auth Provider"
Cohesion: 0.5
Nodes (3): AuthProvider, clearError, package:tfg_frontend/features/auth/data/repositories/auth_repository.dart

## Knowledge Gaps
- **307 isolated node(s):** `App`, `_AuthGate`, `_AuthGateState`, `main`, `build` (+302 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Smoke Test Setup` to `Gym Browse UI Widgets`, `Classes Screen & Provider`, `Async Providers & State`, `App Shell & Navigation`, `Info Card Components`, `Gym List Screen`, `Membership Plans Screen`, `App Bootstrap & Auth Gate`, `App Entry & Provider Setup`, `Login Screen`, `Signup Screen`, `Auth Provider Tests`, `Auth Screen Tests`, `Subscription Screen Tests`?**
  _High betweenness centrality (0.104) - this node is a cross-community bridge._
- **Why does `package:provider/provider.dart` connect `Login Screen` to `Gym Browse UI Widgets`, `Classes Screen & Provider`, `Async Providers & State`, `App Shell & Navigation`, `Info Card Components`, `Gym List Screen`, `Membership Plans Screen`, `App Bootstrap & Auth Gate`, `App Entry & Provider Setup`, `Signup Screen`, `Auth Provider Tests`, `Auth Screen Tests`, `Subscription Screen Tests`, `Smoke Test Setup`?**
  _High betweenness centrality (0.104) - this node is a cross-community bridge._
- **Why does `package:tfg_frontend/features/auth/data/models/auth_models.dart` connect `Data Repositories & HTTP` to `Gym Browse UI Widgets`, `Classes Screen & Provider`, `Async Providers & State`, `App Shell & Navigation`, `App Entry & Provider Setup`, `Subscription & Plans Providers`, `Subscription Plan Tests`, `Auth Provider Tests`, `Auth Screen Tests`, `Subscription Screen Tests`, `Smoke Test Setup`, `Auth Provider Test Suite`, `Subscription Provider Tests`, `Auth Provider`?**
  _High betweenness centrality (0.091) - this node is a cross-community bridge._
- **What connects `App`, `_AuthGate`, `_AuthGateState` to the rest of the system?**
  _307 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Data Repositories & HTTP` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._
- **Should `API Contracts & Session Models` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `Gym Browse UI Widgets` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._