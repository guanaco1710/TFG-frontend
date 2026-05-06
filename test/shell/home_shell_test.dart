import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tfg_frontend/core/storage/token_storage.dart';
import 'package:tfg_frontend/features/bookings/data/models/booking_models.dart';
import 'package:tfg_frontend/features/bookings/data/repositories/booking_repository.dart';
import 'package:tfg_frontend/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:tfg_frontend/shell/home_shell.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

class MockBookingRepository extends Mock implements BookingRepository {}

final _emptyPage = BookingPage(
  content: [],
  page: 0,
  size: 3,
  totalElements: 0,
  totalPages: 0,
  hasMore: false,
);

Widget _wrap({VoidCallback? onLogout}) {
  return MultiProvider(
    providers: [
      Provider<TokenStorage>.value(value: MockTokenStorage()),
      Provider<String>.value(value: 'http://localhost:8080/api/v1'),
    ],
    child: MaterialApp(home: HomeShell(onLogout: onLogout ?? () {})),
  );
}

void main() {
  group('HomeShell', () {
    testWidgets('shows Inicio tab by default', (tester) async {
      await tester.pumpWidget(_wrap());

      expect(find.text('Inicio'), findsWidgets);
      expect(find.byKey(const Key('subscription_button')), findsOneWidget);
      expect(find.byKey(const Key('gyms_button')), findsOneWidget);
    });

    testWidgets('bottom nav has 4 destinations', (tester) async {
      await tester.pumpWidget(_wrap());

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Inicio'), findsWidgets);
      expect(find.text('Clases'), findsOneWidget);
      expect(find.text('Estadísticas'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('tapping Clases switches tab and updates AppBar title', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());

      await tester.tap(find.text('Clases'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Clases')),
        findsOneWidget,
      );
    });

    testWidgets('tapping Estadísticas switches tab and updates AppBar title', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());

      await tester.tap(find.text('Estadísticas'));
      await tester.pump();
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Estadísticas'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping Perfil switches tab and updates AppBar title', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());

      await tester.tap(find.text('Perfil'));
      await tester.pump();
      await tester.pump();

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Perfil')),
        findsOneWidget,
      );
    });

    testWidgets('tapping back to Inicio restores home tab', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.tap(find.text('Clases'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('subscription_button')), findsOneWidget);
    });

    testWidgets('logout button calls onLogout callback', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(onLogout: () => called = true));

      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('AppBar title is Inicio on initial render', (tester) async {
      await tester.pumpWidget(_wrap());

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Inicio')),
        findsOneWidget,
      );
    });

    testWidgets('back gesture triggers SystemNavigator.pop via PopScope', (
      tester,
    ) async {
      final log = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          log.add(call);
          return null;
        },
      );

      await tester.pumpWidget(_wrap());
      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(log.any((c) => c.method == 'SystemNavigator.pop'), isTrue);

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
  });

  group('HomeTab', () {
    late MockBookingRepository bookingRepo;

    setUp(() {
      bookingRepo = MockBookingRepository();
      when(
        () => bookingRepo.fetchMyBookings(
          page: any(named: 'page'),
          size: any(named: 'size'),
          status: any(named: 'status'),
          from: any(named: 'from'),
        ),
      ).thenAnswer((_) async => _emptyPage);
    });

    Widget wrapTab() => MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: MockTokenStorage()),
        Provider<String>.value(value: 'http://localhost:8080/api/v1'),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(repository: bookingRepo),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: HomeTab(
            tokenStorage: MockTokenStorage(),
            baseUrl: 'http://localhost:8080/api/v1',
          ),
        ),
      ),
    );

    testWidgets('renders subscription and gyms buttons', (tester) async {
      await tester.pumpWidget(wrapTab());

      expect(find.byKey(const Key('subscription_button')), findsOneWidget);
      expect(find.byKey(const Key('gyms_button')), findsOneWidget);
      expect(find.text('MI SUSCRIPCIÓN'), findsOneWidget);
      expect(find.text('GIMNASIOS'), findsOneWidget);
    });

    testWidgets(
      'tapping subscription button navigates to subscription screen',
      (tester) async {
        await tester.pumpWidget(wrapTab());

        await tester.tap(find.byKey(const Key('subscription_button')));
        await tester.pumpAndSettle();

        expect(find.text('Mis suscripciones'), findsOneWidget);
      },
    );

    testWidgets('tapping gyms button navigates to gym list screen', (
      tester,
    ) async {
      await tester.pumpWidget(wrapTab());

      await tester.tap(find.byKey(const Key('gyms_button')));
      await tester.pumpAndSettle();

      expect(find.text('Gimnasios'), findsOneWidget);
    });

    testWidgets('renders mis reservas button', (tester) async {
      await tester.pumpWidget(wrapTab());

      expect(find.byKey(const Key('my_bookings_button')), findsOneWidget);
      expect(find.text('MIS RESERVAS'), findsOneWidget);
    });

    testWidgets('tapping mis reservas button navigates to bookings screen', (
      tester,
    ) async {
      await tester.pumpWidget(wrapTab());

      await tester.tap(find.byKey(const Key('my_bookings_button')));
      await tester.pumpAndSettle();

      expect(find.text('Mis Reservas'), findsOneWidget);
    });
  });
}
