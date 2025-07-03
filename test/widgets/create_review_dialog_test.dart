import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreisel_frontend/widgets/create_review_dialog.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';

// Mock implementation for testing
class MockReviewDependencies implements ReviewDialogDependencies {
  final List<Map<String, dynamic>> submittedReviews = [];
  final List<String> errorMessages = [];
  final List<String> successCalls = [];
  final bool shouldThrowError;
  final String? errorToThrow;
  final Duration? delay;

  MockReviewDependencies({
    this.shouldThrowError = false,
    this.errorToThrow,
    this.delay,
  });

  @override
  Future<void> submitReview({
    required int rentalId,
    required int rating,
    String? comment,
  }) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }

    submittedReviews.add({
      'rentalId': rentalId,
      'rating': rating,
      'comment': comment,
    });

    if (shouldThrowError) {
      throw Exception(errorToThrow ?? 'Mock API error');
    }
  }

  @override
  void showErrorDialog(BuildContext context, String message) {
    errorMessages.add(message);
  }

  @override
  void closeDialog(BuildContext context, VoidCallback onSuccess) {
    successCalls.add('success');
    onSuccess();
  }

  Map<String, dynamic>? get lastSubmittedReview => 
      submittedReviews.isNotEmpty ? submittedReviews.last : null;
  String? get lastErrorMessage => 
      errorMessages.isNotEmpty ? errorMessages.last : null;
  bool get hasSuccessCall => successCalls.isNotEmpty;
}

void main() {
  group('CreateReviewDialog Tests', () {
    late Rental testRental;
    late Item testItem;
    late User testUser;

    setUp(() {
      testItem = Item(
        id: 1,
        name: 'Test Ski Equipment',
        size: 'M',
        available: false,
        description: 'High-quality ski equipment',
        brand: 'TestBrand',
        imageUrl: 'https://example.com/ski.jpg',
        averageRating: 4.2,
        reviewCount: 8,
        location: 'PASING',
        gender: 'UNISEX',
        category: 'EQUIPMENT',
        subcategory: 'SKI',
        zustand: 'NEU',
      );

      testUser = User(
        userId: 123,
        fullName: 'Test User',
        email: 'test@hm.edu',
        role: 'USER',
      );

      testRental = Rental(
        id: 1,
        item: testItem,
        user: testUser,
        rentalDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 8),
        returnDate: DateTime(2024, 1, 7),
        extended: false,
        status: 'RETURNED',
      );
    });

    Widget createTestWidget({ReviewDialogDependencies? dependencies}) {
      return MaterialApp(
        home: Scaffold(
          body: CreateReviewDialog(
            rental: testRental,
            onReviewSubmitted: () {},
            dependencies: dependencies,
          ),
        ),
      );
    }

    Widget createDialogInNavigator({
      ReviewDialogDependencies? dependencies,
      VoidCallback? onReviewSubmitted,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CreateReviewDialog(
                    rental: testRental,
                    onReviewSubmitted: onReviewSubmitted ?? () {},
                    dependencies: dependencies,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );
    }

    // Essential Widget Tests
    group('Core Widget Tests', () {
      testWidgets('should build dialog with all essential elements', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(CupertinoAlertDialog), findsOneWidget);
        expect(find.text('Bewertung abgeben'), findsOneWidget);
        expect(find.text('Test Ski Equipment'), findsOneWidget);
        expect(find.byKey(Key('star_button_0')), findsOneWidget);
        expect(find.byKey(Key('star_button_4')), findsOneWidget);
        expect(find.byIcon(Icons.star), findsNWidgets(5));
        expect(find.byKey(Key('comment_field')), findsOneWidget);
        expect(find.byKey(Key('cancel_button')), findsOneWidget);
        expect(find.byKey(Key('submit_button')), findsOneWidget);
      });

      testWidgets('should use production dependencies by default', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        expect(find.byType(CreateReviewDialog), findsOneWidget);
      });
    });

    // Star Rating Coverage
    group('Star Rating Tests', () {
      testWidgets('should update rating when stars are tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byIcon(Icons.star), findsNWidgets(5));

        await tester.tap(find.byKey(Key('star_button_0')));
        await tester.pump();
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.byIcon(Icons.star_border), findsNWidgets(4));

        await tester.tap(find.byKey(Key('star_button_2')));
        await tester.pump();
        expect(find.byIcon(Icons.star), findsNWidgets(3));
      });
    });

    // Comment Input Coverage
    group('Comment Input Tests', () {
      testWidgets('should accept and display text input', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        const testComment = 'This is a great product!';
        await tester.enterText(find.byKey(Key('comment_field')), testComment);
        await tester.pump();

        expect(find.text(testComment), findsOneWidget);
      });

      testWidgets('should handle empty comment input', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.enterText(find.byKey(Key('comment_field')), '');
        await tester.pump();

        expect(find.text('Kommentar (optional)'), findsOneWidget);
      });
    });

    // Successful Submission Coverage
    group('Successful Submission Tests', () {
      testWidgets('should submit review with correct data', (WidgetTester tester) async {
        final mockDeps = MockReviewDependencies();
        bool callbackCalled = false;

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: CreateReviewDialog(
              rental: testRental,
              onReviewSubmitted: () {
                callbackCalled = true;
              },
              dependencies: mockDeps,
            ),
          ),
        ));

        await tester.tap(find.byKey(Key('star_button_3')));
        await tester.pump();

        const testComment = 'Excellent equipment!';
        await tester.enterText(find.byKey(Key('comment_field')), testComment);
        await tester.pump();

        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();

        expect(mockDeps.submittedReviews.length, equals(1));
        final submission = mockDeps.lastSubmittedReview!;
        expect(submission['rentalId'], equals(testRental.id));
        expect(submission['rating'], equals(4));
        expect(submission['comment'], equals(testComment));
        expect(mockDeps.hasSuccessCall, isTrue);
        expect(callbackCalled, isTrue);
      });

      testWidgets('should submit with null comment when empty', (WidgetTester tester) async {
        final mockDeps = MockReviewDependencies();

        await tester.pumpWidget(createTestWidget(dependencies: mockDeps));

        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();

        final submission = mockDeps.lastSubmittedReview!;
        expect(submission['comment'], isNull);
      });

      testWidgets('should trim whitespace from comments', (WidgetTester tester) async {
        final mockDeps = MockReviewDependencies();

        await tester.pumpWidget(createTestWidget(dependencies: mockDeps));

        await tester.enterText(find.byKey(Key('comment_field')), '  trimmed comment  ');
        await tester.pump();

        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();

        final submission = mockDeps.lastSubmittedReview!;
        expect(submission['comment'], equals('trimmed comment'));
      });

      testWidgets('should treat whitespace-only comments as null', (WidgetTester tester) async {
        final mockDeps = MockReviewDependencies();

        await tester.pumpWidget(createTestWidget(dependencies: mockDeps));

        await tester.enterText(find.byKey(Key('comment_field')), '   \n\t   ');
        await tester.pump();

        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();

        final submission = mockDeps.lastSubmittedReview!;
        expect(submission['comment'], isNull);
      });
    });

    // Error Handling Coverage
    group('Error Handling Tests', () {
      testWidgets('should show error when API call fails', (WidgetTester tester) async {
        final mockDeps = MockReviewDependencies(
          shouldThrowError: true,
          errorToThrow: 'Network connection failed',
        );

        await tester.pumpWidget(createTestWidget(dependencies: mockDeps));

        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();

        expect(mockDeps.errorMessages.length, equals(1));
        expect(mockDeps.lastErrorMessage, contains('Network connection failed'));
        expect(mockDeps.submittedReviews.length, equals(1));
        expect(mockDeps.hasSuccessCall, isFalse);
      });

      testWidgets('should re-enable submit button after error', (WidgetTester tester) async {
        final mockDeps = MockReviewDependencies(shouldThrowError: true);

        await tester.pumpWidget(createTestWidget(dependencies: mockDeps));

        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();

        final submitButton = tester.widget<CupertinoDialogAction>(
          find.byKey(Key('submit_button')),
        );
        expect(submitButton.onPressed, isNotNull);
        expect(find.text('Bewertung absenden'), findsOneWidget);
      });

      testWidgets('should handle mounted state during error', (WidgetTester tester) async {
        final mockDeps = MockReviewDependencies(
          shouldThrowError: true,
          delay: Duration(milliseconds: 100),
        );

        await tester.pumpWidget(createTestWidget(dependencies: mockDeps));

        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();

        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

        await tester.pumpWidget(Container());
        await tester.pump(Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
      });
    });

    // Loading State Coverage
    group('Loading State Tests', () {
      testWidgets('should show loading indicator during submission', (WidgetTester tester) async {
        final mockDeps = MockReviewDependencies(delay: Duration(milliseconds: 100));

        await tester.pumpWidget(createTestWidget(dependencies: mockDeps));

        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();

        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
        expect(find.text('Bewertung absenden'), findsNothing);

        await tester.pump(Duration(milliseconds: 150));
        await tester.pump();
      });

      testWidgets('should disable submit button during loading', (WidgetTester tester) async {
        final mockDeps = MockReviewDependencies(delay: Duration(milliseconds: 10));

        await tester.pumpWidget(createTestWidget(dependencies: mockDeps));

        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();

        final submitButton = tester.widget<CupertinoDialogAction>(
          find.byKey(Key('submit_button')),
        );
        expect(submitButton.onPressed, isNull);

        await tester.pump(Duration(milliseconds: 20));
        await tester.pump();
      });

      testWidgets('should prevent multiple submissions during loading', (WidgetTester tester) async {
        final mockDeps = MockReviewDependencies(delay: Duration(milliseconds: 100));

        await tester.pumpWidget(createTestWidget(dependencies: mockDeps));

        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();
        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();
        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();

        await tester.pump(Duration(milliseconds: 150));

        expect(mockDeps.submittedReviews.length, equals(1));
      });
    });

    // Navigation Coverage
    group('Navigation Tests', () {
      testWidgets('should close dialog when cancel is pressed', (WidgetTester tester) async {
        await tester.pumpWidget(createDialogInNavigator());

        await tester.tap(find.text('Show Dialog'));
        await tester.pump();
        expect(find.text('Bewertung abgeben'), findsOneWidget);

        await tester.tap(find.byKey(Key('cancel_button')));
        await tester.pump();
        expect(find.text('Bewertung abgeben'), findsNothing);
      });

      testWidgets('should close dialog after successful submission', (WidgetTester tester) async {
        final mockDeps = MockReviewDependencies();
        bool callbackCalled = false;

        await tester.pumpWidget(createDialogInNavigator(
          dependencies: mockDeps,
          onReviewSubmitted: () {
            callbackCalled = true;
          },
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pump();
        expect(find.text('Bewertung abgeben'), findsOneWidget);

        await tester.tap(find.byKey(Key('submit_button')));
        await tester.pump();

        expect(mockDeps.hasSuccessCall, isTrue);
        expect(callbackCalled, isTrue);
      });
    });

    // ProductionReviewDependencies Coverage
    group('ProductionReviewDependencies Coverage', () {
      testWidgets('should test ProductionReviewDependencies submitReview', (WidgetTester tester) async {
        final productionDeps = ProductionReviewDependencies();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    try {
                      await productionDeps.submitReview(
                        rentalId: 123,
                        rating: 5,
                        comment: 'Test',
                      );
                    } catch (e) {
                      // Exception expected
                    }
                  },
                  child: Text('Test Submit'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Test Submit'));
        await tester.pump();
      });

      testWidgets('should test ProductionReviewDependencies showErrorDialog', (WidgetTester tester) async {
        final productionDeps = ProductionReviewDependencies();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    productionDeps.showErrorDialog(context, 'Test error');
                  },
                  child: Text('Test Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Test Error'));
        await tester.pump();
        
        expect(find.byType(CupertinoAlertDialog), findsOneWidget);
        expect(find.text('Fehler'), findsOneWidget);
        expect(find.text('Test error'), findsOneWidget);
        
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      });

      testWidgets('should test ProductionReviewDependencies closeDialog', (WidgetTester tester) async {
        final productionDeps = ProductionReviewDependencies();
        bool dialogClosed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text('Test'),
                        content: ElevatedButton(
                          onPressed: () {
                            productionDeps.closeDialog(dialogContext, () {
                              dialogClosed = true;
                            });
                          },
                          child: Text('Close Dialog'),
                        ),
                      ),
                    );
                  },
                  child: Text('Test Close'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Test Close'));
        await tester.pump();
        
        expect(find.text('Test'), findsOneWidget);
        
        await tester.tap(find.text('Close Dialog'));
        await tester.pump();
        
        expect(find.text('Test'), findsNothing);
        expect(dialogClosed, isTrue);
      });

      testWidgets('should test ProductionReviewDependencies with CreateReviewDialog integration', (WidgetTester tester) async {
        final productionDeps = ProductionReviewDependencies();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CreateReviewDialog(
                rental: testRental,
                onReviewSubmitted: () {},
                dependencies: productionDeps,
              ),
            ),
          ),
        );

        expect(find.text('Bewertung abgeben'), findsOneWidget);
        
        await tester.tap(find.byKey(Key('cancel_button')));
        await tester.pump();
      });
    });
  });
}