//import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/services/api_service.dart';
import 'package:kreisel_frontend/widgets/rent_item_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kreisel_frontend/models/user_model.dart';

// Mock implementations
class MockHttpClient implements HttpClientInterface {
  final Map<String, http.Response> _responseMap = {};
  final List<Map<String, dynamic>> _requests = [];

  void setResponse(String endpoint, http.Response response) {
    _responseMap[endpoint] = response;
  }

  List<Map<String, dynamic>> get requests => _requests;

  void reset() {
    _responseMap.clear();
    _requests.clear();
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    _requests.add({'method': 'GET', 'url': url.toString(), 'headers': headers});

    final endpoint = _getEndpoint(url);
    if (_responseMap.containsKey(endpoint)) {
      return _responseMap[endpoint]!;
    }

    return http.Response('{"message": "Not found"}', 404);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    _requests.add({
      'method': 'POST',
      'url': url.toString(),
      'headers': headers,
      'body': body,
    });

    final endpoint = _getEndpoint(url);
    if (_responseMap.containsKey(endpoint)) {
      return _responseMap[endpoint]!;
    }

    return http.Response('{"message": "Not found"}', 404);
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    _requests.add({
      'method': 'PUT',
      'url': url.toString(),
      'headers': headers,
      'body': body,
    });

    final endpoint = _getEndpoint(url);
    if (_responseMap.containsKey(endpoint)) {
      return _responseMap[endpoint]!;
    }

    return http.Response('{"message": "Not found"}', 404);
  }

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    _requests.add({
      'method': 'DELETE',
      'url': url.toString(),
      'headers': headers,
    });

    final endpoint = _getEndpoint(url);
    if (_responseMap.containsKey(endpoint)) {
      return _responseMap[endpoint]!;
    }

    return http.Response('{"message": "Not found"}', 404);
  }

  String _getEndpoint(Uri url) {
    final path = url.path;
    if (path.contains('/rentals/rent')) {
      return 'rentItem';
    } else if (path.contains('/users/me')) {
      return 'getCurrentUser';
    }
    return path;
  }
}

class MockTokenStorage implements TokenStorageInterface {
  String? _token;
  String? _cookie;

  @override
  Future<String?> getCookie() async {
    return _cookie;
  }

  @override
  Future<String?> getToken() async {
    return _token;
  }

  @override
  Future<void> removeTokens() async {
    _token = null;
    _cookie = null;
  }

  @override
  Future<void> saveCookie(String cookie) async {
    _cookie = cookie;
  }

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  void setToken(String? token) {
    _token = token;
  }
}

void main() {
  late MockHttpClient mockHttpClient;
  late MockTokenStorage mockTokenStorage;
  const String testBaseUrl = 'http://test-api.example.com/api';

  // Test data
  final testItem = Item(
    id: 123,
    name: 'Test Skis',
    brand: 'Alpine Pro',
    size: 'M',
    available: true,
    location: 'PASING',
    gender: 'UNISEX',
    category: 'EQUIPMENT',
    subcategory: 'SKI',
    zustand: 'NEU',
  );

  // Function to create the test widget
  Widget createTestWidget({
    required Item item,
    required VoidCallback onRented,
  }) {
    return MaterialApp(
      home: Material(
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => RentItemDialog(item: item, onRented: onRented),
                );
              },
              child: Text('Open Dialog'),
            );
          },
        ),
      ),
    );
  }

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockTokenStorage = MockTokenStorage();

    mockTokenStorage.setToken('test_token');

    ApiService.configure(
      httpClient: mockHttpClient,
      tokenStorage: mockTokenStorage,
      baseUrl: testBaseUrl,
    );

    ApiService.currentUser = User(
      userId: 1,
      fullName: 'Test User',
      email: 'test@hm.edu',
      role: 'USER',
    );

    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    mockHttpClient.reset();
    ApiService.resetToDefault();
  });

  group('RentItemDialog Tests', () {
    // Essential UI Tests
    group('UI Tests', () {
      testWidgets('displays item information correctly', (WidgetTester tester) async {
        // ignore: unused_local_variable
        bool rentCallbackCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            item: testItem,
            onRented: () => rentCallbackCalled = true,
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Test Skis ausleihen'), findsOneWidget);
        expect(find.text('Marke: Alpine Pro'), findsOneWidget);
        expect(find.text('Größe: M'), findsOneWidget);
        expect(find.text('Ausleihdauer wählen:'), findsOneWidget);
        expect(find.text('1 Mnt.'), findsOneWidget);
        expect(find.text('2 Mnte.'), findsOneWidget);
        expect(find.text('3 Mnte.'), findsOneWidget);
        expect(find.text('Abbrechen'), findsOneWidget);
        expect(find.text('Jetzt ausleihen'), findsOneWidget);
        expect(find.textContaining('Rückgabedatum:'), findsOneWidget);
      });

      testWidgets('selecting different durations updates return date', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(item: testItem, onRented: () {}),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        final initialDateText = (tester.widget(find.textContaining('Rückgabedatum:')) as Text).data;

        await tester.tap(find.text('2 Mnte.'));
        await tester.pumpAndSettle();

        final updatedDateText = (tester.widget(find.textContaining('Rückgabedatum:')) as Text).data;

        expect(initialDateText != updatedDateText, true);
      });

      testWidgets('handles item with missing optional fields', (WidgetTester tester) async {
        final itemWithoutBrandSize = Item(
          id: 456,
          name: 'Basic Item',
          available: true,
          location: 'PASING',
          gender: 'UNISEX',
          category: 'EQUIPMENT',
          subcategory: 'HELME',
          zustand: 'NEU',
        );

        await tester.pumpWidget(
          createTestWidget(item: itemWithoutBrandSize, onRented: () {}),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Basic Item ausleihen'), findsOneWidget);
        expect(find.text('Marke:'), findsNothing);
        expect(find.text('Größe:'), findsNothing);
      });
    });

    // Cancel Button Coverage
    group('Cancel Tests', () {
      testWidgets('cancel button closes the dialog without renting', (WidgetTester tester) async {
        bool rentCallbackCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            item: testItem,
            onRented: () => rentCallbackCalled = true,
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();

        expect(find.text('Test Skis ausleihen'), findsNothing);
        expect(mockHttpClient.requests.isEmpty, true);
        expect(rentCallbackCalled, false);
      });
    });

    // Success Path Coverage (Critical for Coverage)
    group('Success Path Tests', () {
      testWidgets('successful rental shows success dialog and calls onRented callback', (WidgetTester tester) async {
        bool rentCallbackCalled = false;

        mockHttpClient.setResponse(
          'rentItem',
          http.Response('{"message": "Success"}', 200),
        );

        await tester.pumpWidget(
          createTestWidget(
            item: testItem,
            onRented: () => rentCallbackCalled = true,
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Test Skis ausleihen'), findsOneWidget);

        await tester.tap(find.text('Jetzt ausleihen'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Success dialog coverage
        expect(find.text('Erfolgreich ausgeliehen'), findsOneWidget);
        expect(find.textContaining('Test Skis wurde bis zum'), findsOneWidget);
        expect(find.textContaining('reserviert.'), findsOneWidget);
        expect(rentCallbackCalled, isTrue);
        expect(find.text('Test Skis ausleihen'), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text('Erfolgreich ausgeliehen'), findsNothing);
      });

      testWidgets('successful rental with 2 months duration', (WidgetTester tester) async {
        bool rentCallbackCalled = false;

        mockHttpClient.setResponse(
          'rentItem',
          http.Response('{"message": "Success"}', 200),
        );

        await tester.pumpWidget(
          createTestWidget(
            item: testItem,
            onRented: () => rentCallbackCalled = true,
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('2 Mnte.'));
        await tester.pump();

        await tester.tap(find.text('Jetzt ausleihen'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Erfolgreich ausgeliehen'), findsOneWidget);
        expect(rentCallbackCalled, isTrue);
      });

      testWidgets('successful rental with 3 months duration', (WidgetTester tester) async {
        bool rentCallbackCalled = false;

        mockHttpClient.setResponse(
          'rentItem',
          http.Response('{"message": "Success"}', 200),
        );

        await tester.pumpWidget(
          createTestWidget(
            item: testItem,
            onRented: () => rentCallbackCalled = true,
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('3 Mnte.'));
        await tester.pump();

        await tester.tap(find.text('Jetzt ausleihen'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Erfolgreich ausgeliehen'), findsOneWidget);
        expect(rentCallbackCalled, isTrue);
      });
    });

    // Error Handling Coverage
    group('Error Handling Tests', () {
      testWidgets('unauthorized rental shows login error', (WidgetTester tester) async {
        // ignore: unused_local_variable
        bool rentCallbackCalled = false;

        mockHttpClient.setResponse(
          'rentItem',
          http.Response('{"message": "Unauthorized"}', 401),
        );

        await tester.pumpWidget(
          createTestWidget(
            item: testItem,
            onRented: () => rentCallbackCalled = true,
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Jetzt ausleihen'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Fehler beim Ausleihen'), findsOneWidget);
        expect(find.textContaining('Session abgelaufen'), findsOneWidget);
        expect(await mockTokenStorage.getToken(), isNull);
      });

      testWidgets('handles forbidden status with correct error message', (WidgetTester tester) async {
        mockHttpClient.setResponse(
          'rentItem',
          http.Response('{"message": "Access denied"}', 403),
        );

        await tester.pumpWidget(
          createTestWidget(item: testItem, onRented: () {}),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Jetzt ausleihen'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Fehler beim Ausleihen'), findsOneWidget);
        expect(find.textContaining('Keine Berechtigung'), findsOneWidget);
        expect(await mockTokenStorage.getToken(), isNull);
      });

      testWidgets('error dialog OK button closes dialog properly', (WidgetTester tester) async {
        mockHttpClient.setResponse(
          'rentItem',
          http.Response('{"message": "Test error"}', 400),
        );

        await tester.pumpWidget(
          createTestWidget(item: testItem, onRented: () {}),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Jetzt ausleihen'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Fehler beim Ausleihen'), findsOneWidget);
        expect(find.textContaining('Test error'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text('Fehler beim Ausleihen'), findsNothing);
      });

      testWidgets('error dialog with network error shows and closes properly', (WidgetTester tester) async {
        mockHttpClient.setResponse(
          'rentItem',
          http.Response('{"message": "Network error"}', 500),
        );

        await tester.pumpWidget(
          createTestWidget(item: testItem, onRented: () {}),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Jetzt ausleihen'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Fehler beim Ausleihen'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text('Fehler beim Ausleihen'), findsNothing);
      });
    });
  });
}