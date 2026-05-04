import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tfg_frontend/features/auth/data/models/auth_models.dart';
import 'package:tfg_frontend/features/gyms/data/models/gym_models.dart';
import 'package:tfg_frontend/features/gyms/data/repositories/gym_repository.dart';
import 'package:tfg_frontend/features/gyms/presentation/providers/gym_list_provider.dart';

class MockGymRepository extends Mock implements GymRepository {}

const _gym1 = Gym(
  id: 1,
  name: 'GymBook Central',
  address: 'Calle Mayor 1',
  city: 'Madrid',
  active: true,
);
const _gym2 = Gym(
  id: 2,
  name: 'FitLife North',
  address: 'Av. Norte 22',
  city: 'Barcelona',
  active: true,
);

const _page1 = GymPage(
  content: [_gym1],
  page: 0,
  size: 20,
  totalElements: 1,
  totalPages: 1,
  hasMore: false,
);
const _page1HasMore = GymPage(
  content: [_gym1],
  page: 0,
  size: 20,
  totalElements: 2,
  totalPages: 2,
  hasMore: true,
);
const _page2 = GymPage(
  content: [_gym2],
  page: 1,
  size: 20,
  totalElements: 2,
  totalPages: 2,
  hasMore: false,
);

void main() {
  late MockGymRepository repo;
  late GymListProvider provider;

  setUp(() {
    repo = MockGymRepository();
    provider = GymListProvider(repository: repo);
  });

  group('loadGyms', () {
    test('transitions to loading then loaded and sets gyms', () async {
      when(() => repo.fetchGyms(page: 0)).thenAnswer((_) async => _page1);

      final states = <GymListLoadState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadGyms();

      expect(states, [GymListLoadState.loading, GymListLoadState.loaded]);
      expect(provider.gyms.length, 1);
      expect(provider.gyms[0].name, 'GymBook Central');
      expect(provider.hasMore, false);
      expect(provider.errorMessage, isNull);
    });

    test('sets hasMore=true when page has more results', () async {
      when(
        () => repo.fetchGyms(page: 0),
      ).thenAnswer((_) async => _page1HasMore);

      await provider.loadGyms();

      expect(provider.hasMore, true);
    });

    test('transitions to error and sets message on ApiException', () async {
      when(() => repo.fetchGyms(page: 0)).thenThrow(
        const ApiException(
          status: 500,
          error: 'ServerError',
          message: 'Server down',
          path: '/gyms',
        ),
      );

      await provider.loadGyms();

      expect(provider.state, GymListLoadState.error);
      expect(provider.errorMessage, 'Server down');
    });

    test('transitions to error on generic exception', () async {
      when(() => repo.fetchGyms(page: 0)).thenThrow(Exception('network'));

      await provider.loadGyms();

      expect(provider.state, GymListLoadState.error);
      expect(provider.errorMessage, isNotNull);
    });
  });

  group('query setter and _search', () {
    test('updates query immediately and notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.query = 'test';

      expect(provider.query, 'test');
      expect(notifyCount, greaterThan(0));

      provider.dispose(); // cancel the pending debounce timer
    });

    test('triggers _search after 300 ms debounce', () {
      when(
        () => repo.fetchGyms(page: 0, name: 'gym'),
      ).thenAnswer((_) async => _page1);

      fakeAsync((fake) {
        provider.query = 'gym';

        verifyNever(() => repo.fetchGyms(page: 0, name: 'gym'));

        fake.elapse(const Duration(milliseconds: 300));
        fake.flushMicrotasks();

        verify(() => repo.fetchGyms(page: 0, name: 'gym')).called(1);
        expect(provider.gyms.length, 1);
      });
    });

    test('debounces rapid changes — only fires for last value', () {
      when(
        () => repo.fetchGyms(page: 0, name: 'done'),
      ).thenAnswer((_) async => _page1);

      fakeAsync((fake) {
        provider.query = 'a';
        fake.elapse(const Duration(milliseconds: 100));
        provider.query = 'done';
        fake.elapse(const Duration(milliseconds: 300));
        fake.flushMicrotasks();

        verifyNever(() => repo.fetchGyms(page: 0, name: 'a'));
        verify(() => repo.fetchGyms(page: 0, name: 'done')).called(1);
      });
    });

    test('passes null name to repository when query is empty', () {
      when(() => repo.fetchGyms(page: 0)).thenAnswer((_) async => _page1);

      fakeAsync((fake) {
        provider.query = '';
        fake.elapse(const Duration(milliseconds: 300));
        fake.flushMicrotasks();

        verify(() => repo.fetchGyms(page: 0)).called(1);
      });
    });

    test('_search sets error state on ApiException', () {
      when(() => repo.fetchGyms(page: 0, name: 'fail')).thenThrow(
        const ApiException(
          status: 403,
          error: 'Forbidden',
          message: 'Access denied',
          path: '/gyms',
        ),
      );

      fakeAsync((fake) {
        provider.query = 'fail';
        fake.elapse(const Duration(milliseconds: 300));
        fake.flushMicrotasks();

        expect(provider.state, GymListLoadState.error);
        expect(provider.errorMessage, 'Access denied');
      });
    });

    test('_search sets error state on generic exception', () {
      when(
        () => repo.fetchGyms(page: 0, name: 'fail'),
      ).thenThrow(Exception('network'));

      fakeAsync((fake) {
        provider.query = 'fail';
        fake.elapse(const Duration(milliseconds: 300));
        fake.flushMicrotasks();

        expect(provider.state, GymListLoadState.error);
        expect(provider.errorMessage, isNotNull);
      });
    });
  });

  group('loadMore', () {
    test('appends items and clears hasMore when page has no more', () async {
      when(
        () => repo.fetchGyms(page: 0),
      ).thenAnswer((_) async => _page1HasMore);
      when(() => repo.fetchGyms(page: 1)).thenAnswer((_) async => _page2);

      await provider.loadGyms();
      await provider.loadMore();

      expect(provider.gyms.length, 2);
      expect(provider.gyms[1].name, 'FitLife North');
      expect(provider.hasMore, false);
      expect(provider.isLoadingMore, false);
    });

    test('isLoadingMore is true while pending and false after', () async {
      when(
        () => repo.fetchGyms(page: 0),
      ).thenAnswer((_) async => _page1HasMore);
      when(() => repo.fetchGyms(page: 1)).thenAnswer((_) async => _page2);

      await provider.loadGyms();

      final values = <bool>[];
      provider.addListener(() => values.add(provider.isLoadingMore));

      await provider.loadMore();

      expect(values, containsAllInOrder([true, false]));
    });

    test('does nothing when hasMore is false', () async {
      when(() => repo.fetchGyms(page: 0)).thenAnswer((_) async => _page1);

      await provider.loadGyms();
      final gymsBeforeLoadMore = provider.gyms.length;

      await provider.loadMore();

      expect(provider.gyms.length, gymsBeforeLoadMore);
    });

    test('does nothing when state is not loaded', () async {
      await provider.loadMore();

      expect(provider.gyms, isEmpty);
    });

    test('uses current query as name filter', () async {
      // loadGyms uses no name, but query is set before loadMore
      when(
        () => repo.fetchGyms(page: 0),
      ).thenAnswer((_) async => _page1HasMore);
      when(
        () => repo.fetchGyms(page: 1, name: 'gym'),
      ).thenAnswer((_) async => _page2);

      await provider.loadGyms();
      provider.query =
          'gym'; // sets _query immediately; debounce starts but won't fire in time
      await provider.loadMore(); // should call fetchGyms(page: 1, name: 'gym')

      expect(provider.gyms.length, 2);
      verify(() => repo.fetchGyms(page: 1, name: 'gym')).called(1);

      provider.dispose(); // cancel the pending debounce timer
    });

    test('silently swallows ApiException and keeps existing items', () async {
      when(
        () => repo.fetchGyms(page: 0),
      ).thenAnswer((_) async => _page1HasMore);
      when(() => repo.fetchGyms(page: 1)).thenThrow(
        const ApiException(
          status: 500,
          error: 'e',
          message: 'm',
          path: '/gyms',
        ),
      );

      await provider.loadGyms();
      await provider.loadMore();

      expect(provider.state, GymListLoadState.loaded);
      expect(provider.gyms.length, 1);
      expect(provider.isLoadingMore, false);
    });

    test(
      'silently swallows generic exception and keeps existing items',
      () async {
        when(
          () => repo.fetchGyms(page: 0),
        ).thenAnswer((_) async => _page1HasMore);
        when(() => repo.fetchGyms(page: 1)).thenThrow(Exception('network'));

        await provider.loadGyms();
        await provider.loadMore();

        expect(provider.state, GymListLoadState.loaded);
        expect(provider.isLoadingMore, false);
      },
    );
  });

  group('dispose', () {
    test('cancels pending debounce timer so _search is not called', () {
      fakeAsync((fake) {
        provider.query = 'test';
        provider.dispose();

        fake.elapse(const Duration(milliseconds: 300));

        verifyNever(() => repo.fetchGyms(page: 0, name: 'test'));
      });
    });
  });
}
