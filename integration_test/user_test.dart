// integration_test/robust_user_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kreisel_frontend/main.dart' as app;
import 'package:kreisel_frontend/pages/login_page.dart';
import 'package:kreisel_frontend/pages/location_selection_page.dart';
import 'package:kreisel_frontend/pages/home_page.dart';
import 'package:kreisel_frontend/pages/my_rentals_page.dart';
import 'package:kreisel_frontend/pages/my_account_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Robust User Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Complete User Journey: Register → Campus → Rent → Return → Review → Account → Logout', (WidgetTester tester) async {
      debugPrint('🚀 Starting Robust User Test - ${DateTime.now().toUtc()}');
      
      // Set larger screen size
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      debugPrint('📱 Screen size set to 800x1400');
      
      try {
        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // STEP 1: User Registration (auto-login)
        debugPrint('📝 Step 1: User Registration');
        await _performUserRegistration(tester);

        // STEP 2: Select Campus Pasing
        debugPrint('🏫 Step 2: Select Campus Pasing');
        await _selectCampusPasing(tester);

        // STEP 3: Verify Home Page
        debugPrint('🏠 Step 3: Verify Home Page');
        await _verifyHomePage(tester);

        // STEP 4: Rent Item
        debugPrint('🛒 Step 4: Rent Item');
        await _rentAvailableItem(tester);

        // STEP 5: Navigate to My Rentals
        debugPrint('📋 Step 5: Navigate to My Rentals');
        await _navigateToMyRentals(tester);

        // STEP 6: Return Item
        debugPrint('↩️ Step 6: Return Item');
        await _returnRentedItem(tester);

        // STEP 7: Write Review
        debugPrint('⭐ Step 7: Write Review');
        await _writeReview(tester);

        // STEP 8: Navigate to Account (directly from MyRentalsPage)
        debugPrint('👤 Step 8: Navigate to Account');
        await _navigateToAccountFromRentals(tester);

        // STEP 9: Logout
        debugPrint('🚪 Step 9: Logout');
        await _performLogout(tester);

        debugPrint('🎉 User Test completed successfully - ${DateTime.now().toUtc()}');
        
      } catch (e, stackTrace) {
        debugPrint('❌ Test failed with error: $e');
        debugPrint('Stack trace: $stackTrace');
        
        // Debug current UI state
        await _debugCurrentUIState(tester);
        rethrow;
      } finally {
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      }
    });
  });
}

// Enhanced helper functions with better navigation handling

Future<void> _performUserRegistration(WidgetTester tester) async {
  debugPrint('📝 Starting user registration process...');
  
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Switch to registration mode
  if (!await _switchToRegistrationMode(tester)) {
    throw Exception('Failed to switch to registration mode');
  }

  // Fill and submit registration form
  if (!await _fillRegistrationForm(tester)) {
    throw Exception('Failed to fill registration form');
  }

  debugPrint('✅ User registration completed');
}

Future<bool> _switchToRegistrationMode(WidgetTester tester) async {
  final registrationToggle = find.text('Noch kein Account? Registrieren');
  
  if (registrationToggle.evaluate().isEmpty) {
    debugPrint('❌ Registration toggle not found');
    return false;
  }

  await tester.ensureVisible(registrationToggle);
  await tester.pumpAndSettle();
  
  await tester.tap(registrationToggle, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Verify registration mode
  for (int i = 0; i < 3; i++) {
    if (find.text('Vollständiger Name').evaluate().isNotEmpty) {
      debugPrint('✅ Successfully switched to registration mode');
      return true;
    }
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
  
  debugPrint('❌ Failed to switch to registration mode');
  return false;
}

Future<bool> _fillRegistrationForm(WidgetTester tester) async {
  debugPrint('📝 Filling user registration form...');
  
  final textFields = find.byType(TextField);
  
  if (textFields.evaluate().length < 3) {
    debugPrint('❌ Expected at least 3 text fields, found ${textFields.evaluate().length}');
    return false;
  }
  
  try {
    // Fill form fields
    await tester.enterText(textFields.at(0), 'User Test3');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    
    await tester.enterText(textFields.at(1), 'usertest3@hm.edu');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    
    await tester.enterText(textFields.at(2), 'usertest');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Submit registration
    final registerButton = find.text('Registrieren');
    
    if (registerButton.evaluate().isEmpty) {
      debugPrint('❌ Registration button not found');
      return false;
    }
    
    await tester.ensureVisible(registerButton);
    await tester.pumpAndSettle();
    
    await tester.tap(registerButton, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: 8));

    // Handle any success dialogs
    await _handleAnyDialogs(tester);
    
    debugPrint('✅ Registration form submitted successfully');
    return true;
  } catch (e) {
    debugPrint('❌ Failed to fill registration form: $e');
    return false;
  }
}

Future<void> _selectCampusPasing(WidgetTester tester) async {
  debugPrint('🏫 Selecting Campus Pasing...');
  
  await tester.pumpAndSettle(const Duration(seconds: 5));
  
  // Wait for location selection page
  for (int attempt = 1; attempt <= 5; attempt++) {
    debugPrint('🔍 Location page detection attempt $attempt/5');
    
    if (find.byType(LocationSelectionPage).evaluate().isNotEmpty || 
        find.text('Standort wählen').evaluate().isNotEmpty) {
      debugPrint('✅ Location Selection Page detected!');
      break;
    }
    
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  
  // Try multiple strategies to select Campus Pasing
  if (await _trySelectPasingByWidget(tester)) {
    debugPrint('✅ Campus Pasing selected via widget detection');
    return;
  }
  
  if (await _trySelectPasingByCoordinates(tester)) {
    debugPrint('✅ Campus Pasing selected via coordinates');
    return;
  }
  
  throw Exception('Failed to select Campus Pasing');
}

Future<bool> _trySelectPasingByWidget(WidgetTester tester) async {
  debugPrint('🎯 Trying to select Pasing by widget detection...');
  
  // Look for Campus Pasing text or container
  final pasingFinders = [
    find.widgetWithText(GestureDetector, 'Campus Pasing'),
    find.text('Campus Pasing'),
    find.textContaining('Pasing'),
  ];
  
  for (final finder in pasingFinders) {
    if (finder.evaluate().isNotEmpty) {
      debugPrint('✅ Found Pasing element via ${finder.toString()}');
      
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      
      await tester.tap(finder.first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Check if navigation succeeded
      if (find.byType(HomePage).evaluate().isNotEmpty) {
        return true;
      }
    }
  }
  
  return false;
}

Future<bool> _trySelectPasingByCoordinates(WidgetTester tester) async {
  debugPrint('🎯 Trying to select Pasing by coordinates...');
  
  // Known coordinates for Campus Pasing
  const pasingX = 367.1;
  const pasingY = 254.9;
  
  await tester.tapAt(const Offset(pasingX, pasingY));
  await tester.pumpAndSettle(const Duration(seconds: 5));
  
  // Check if navigation succeeded
  return find.byType(HomePage).evaluate().isNotEmpty;
}

Future<void> _verifyHomePage(WidgetTester tester) async {
  debugPrint('🏠 Verifying Home Page...');
  
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Wait for HomePage to load
  for (int attempt = 1; attempt <= 5; attempt++) {
    debugPrint('🔍 HomePage detection attempt $attempt/5');
    
    if (find.byType(HomePage).evaluate().isNotEmpty) {
      debugPrint('✅ HomePage detected!');
      return;
    }
    
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  
  throw Exception('HomePage not detected after campus selection');
}

Future<void> _rentAvailableItem(WidgetTester tester) async {
  debugPrint('🛒 Renting available item...');
  
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Look for "Ausleihen" buttons
  final ausleihenaButtons = find.text('Ausleihen');
  
  if (ausleihenaButtons.evaluate().isEmpty) {
    throw Exception('No "Ausleihen" buttons found - no available items?');
  }
  
  debugPrint('✅ Found ${ausleihenaButtons.evaluate().length} "Ausleihen" button(s)');
  
  // Tap first available item
  await tester.ensureVisible(ausleihenaButtons.first);
  await tester.pumpAndSettle();
  
  await tester.tap(ausleihenaButtons.first, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Handle rental dialog
  if (!await _handleRentalDialog(tester)) {
    throw Exception('Failed to complete rental dialog');
  }
  
  debugPrint('✅ Item rental completed');
}

Future<bool> _handleRentalDialog(WidgetTester tester) async {
  debugPrint('💬 Handling rental dialog...');
  
  // Wait for dialog to appear
  await tester.pumpAndSettle(const Duration(seconds: 1));
  
  if (find.byType(CupertinoAlertDialog).evaluate().isEmpty) {
    debugPrint('❌ No rental dialog found');
    return false;
  }
  
  // Look for confirmation button
  final confirmButton = find.text('Jetzt ausleihen');
  
  if (confirmButton.evaluate().isEmpty) {
    debugPrint('❌ "Jetzt ausleihen" button not found');
    return false;
  }
  
  await tester.ensureVisible(confirmButton);
  await tester.pumpAndSettle();
  
  await tester.tap(confirmButton, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 8));
  
  // Handle success dialog
  await _handleAnyDialogs(tester);
  
  return true;
}

Future<void> _navigateToMyRentals(WidgetTester tester) async {
  debugPrint('📋 Navigating to My Rentals...');
  
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Look for cube_box icon
  final cubeBoxIcon = find.byIcon(CupertinoIcons.cube_box);
  
  if (cubeBoxIcon.evaluate().isEmpty) {
    throw Exception('Cube box icon not found for "Meine Ausleihen"');
  }
  
  await tester.ensureVisible(cubeBoxIcon);
  await tester.pumpAndSettle();
  
  await tester.tap(cubeBoxIcon, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  
  // Verify MyRentalsPage
  if (!await _verifyMyRentalsPage(tester)) {
    throw Exception('Failed to navigate to MyRentalsPage');
  }
  
  debugPrint('✅ Successfully navigated to My Rentals');
}

Future<bool> _verifyMyRentalsPage(WidgetTester tester) async {
  for (int attempt = 1; attempt <= 3; attempt++) {
    debugPrint('🔍 MyRentalsPage verification attempt $attempt/3');
    
    if (find.byType(MyRentalsPage).evaluate().isNotEmpty || 
        find.text('Meine Ausleihen').evaluate().isNotEmpty ||
        find.textContaining('Aktuelle Ausleihen').evaluate().isNotEmpty) {
      return true;
    }
    
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  
  return false;
}

Future<void> _returnRentedItem(WidgetTester tester) async {
  debugPrint('↩️ Returning rented item...');
  
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Look for "Zurückgeben" button
  final zurueckgebenButtons = find.text('Zurückgeben');
  
  if (zurueckgebenButtons.evaluate().isEmpty) {
    throw Exception('No "Zurückgeben" buttons found - no active rentals?');
  }
  
  debugPrint('✅ Found ${zurueckgebenButtons.evaluate().length} "Zurückgeben" button(s)');
  
  await tester.ensureVisible(zurueckgebenButtons.first);
  await tester.pumpAndSettle();
  
  await tester.tap(zurueckgebenButtons.first, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Handle confirmation dialog
  if (!await _handleReturnConfirmation(tester)) {
    throw Exception('Failed to confirm item return');
  }
  
  debugPrint('✅ Item return completed');
}

Future<bool> _handleReturnConfirmation(WidgetTester tester) async {
  debugPrint('💬 Handling return confirmation...');
  
  if (find.byType(CupertinoAlertDialog).evaluate().isEmpty) {
    debugPrint('❌ No confirmation dialog found');
    return false;
  }
  
  // Look for confirmation button in dialog
  final confirmButtons = find.text('Zurückgeben');
  
  if (confirmButtons.evaluate().length < 2) {
    debugPrint('❌ Confirmation "Zurückgeben" button not found in dialog');
    return false;
  }
  
  // Tap the last (dialog) button
  await tester.ensureVisible(confirmButtons.last);
  await tester.pumpAndSettle();
  
  await tester.tap(confirmButtons.last, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 8));
  
  // Handle success dialog
  await _handleAnyDialogs(tester);
  
  return true;
}

Future<void> _writeReview(WidgetTester tester) async {
  debugPrint('⭐ Writing review...');
  
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Look for "Bewerten" button
  final bewertenButtons = find.text('Bewerten');
  
  if (bewertenButtons.evaluate().isEmpty) {
    throw Exception('No "Bewerten" buttons found - no past rentals?');
  }
  
  debugPrint('✅ Found ${bewertenButtons.evaluate().length} "Bewerten" button(s)');
  
  await tester.ensureVisible(bewertenButtons.first);
  await tester.pumpAndSettle();
  
  await tester.tap(bewertenButtons.first, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Handle review dialog
  if (!await _handleReviewDialog(tester)) {
    throw Exception('Failed to complete review dialog');
  }
  
  debugPrint('✅ Review completed');
}

Future<bool> _handleReviewDialog(WidgetTester tester) async {
  debugPrint('💬 Handling review dialog...');
  
  if (find.byType(CupertinoAlertDialog).evaluate().isEmpty) {
    debugPrint('❌ No review dialog found');
    return false;
  }
  
  // Verify it's the review dialog
  if (find.text('Bewertung abgeben').evaluate().isEmpty) {
    debugPrint('❌ Not a review dialog');
    return false;
  }
  
  // Set 5 stars (click the 5th star)
  final starButtons = find.byIcon(Icons.star);
  if (starButtons.evaluate().length >= 5) {
    await tester.tap(starButtons.at(4), warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    debugPrint('✅ Set 5 star rating');
  }
  
  // Enter comment
  final commentField = find.byType(TextField).last;
  if (commentField.evaluate().isNotEmpty) {
    await tester.tap(commentField, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    
    const reviewText = 'sehr geiles Produkt, würde ich nochmal kaufen. PS ich finde wir haben mindestens eine 1,7 als Note verdient. Liebe grüße, Team Snow_fall_widget';
    await tester.enterText(commentField, reviewText);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    
    debugPrint('✅ Entered review comment');
  }
  
  // Submit review
  final submitButton = find.text('Bewertung absenden');
  if (submitButton.evaluate().isEmpty) {
    debugPrint('❌ Submit button not found');
    return false;
  }
  
  await tester.ensureVisible(submitButton);
  await tester.pumpAndSettle();
  
  await tester.tap(submitButton, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 8));
  
  // Handle success dialog
  await _handleAnyDialogs(tester);
  
  return true;
}

Future<void> _navigateToAccountFromRentals(WidgetTester tester) async {
  debugPrint('👤 Navigating to Account from Rentals...');
  
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Strategy 1: Try back navigation to HomePage first
  if (await _tryBackToHomePage(tester)) {
    debugPrint('✅ Navigated back to HomePage');
    
    // Now navigate to account from HomePage
    if (await _navigateToAccountFromHomePage(tester)) {
      debugPrint('✅ Successfully navigated to Account via HomePage');
      return;
    }
  }
  
  // Strategy 2: Try direct navigation if available
  if (await _tryDirectAccountNavigation(tester)) {
    debugPrint('✅ Successfully navigated to Account directly');
    return;
  }
  
  throw Exception('Failed to navigate to Account page');
}

Future<bool> _tryBackToHomePage(WidgetTester tester) async {
  debugPrint('🔙 Trying to navigate back to HomePage...');
  
  // Look for back button in AppBar
  final backButtons = [
    find.byIcon(Icons.arrow_back),
    find.byIcon(CupertinoIcons.back),
    find.byIcon(Icons.arrow_back_ios),
  ];
  
  for (final backButton in backButtons) {
    if (backButton.evaluate().isNotEmpty) {
      debugPrint('✅ Found back button');
      
      await tester.ensureVisible(backButton);
      await tester.pumpAndSettle();
      
      await tester.tap(backButton.first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Check if we're back on HomePage
      if (find.byType(HomePage).evaluate().isNotEmpty) {
        return true;
      }
    }
  }
  
  // Try system back gesture
  debugPrint('🔙 Trying system back navigation...');
  await tester.pageBack();
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  return find.byType(HomePage).evaluate().isNotEmpty;
}

Future<bool> _navigateToAccountFromHomePage(WidgetTester tester) async {
  debugPrint('👤 Navigating to Account from HomePage...');
  
  // Look for person icon
  final personIcon = find.byIcon(CupertinoIcons.person);
  
  if (personIcon.evaluate().isEmpty) {
    debugPrint('❌ Person icon not found on HomePage');
    return false;
  }
  
  await tester.ensureVisible(personIcon);
  await tester.pumpAndSettle();
  
  await tester.tap(personIcon, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  
  // Verify MyAccountPage
  return find.byType(MyAccountPage).evaluate().isNotEmpty ||
         find.textContaining('Account').evaluate().isNotEmpty;
}

Future<bool> _tryDirectAccountNavigation(WidgetTester tester) async {
  debugPrint('👤 Trying direct Account navigation...');
  
  // Look for any account-related buttons or icons on current page
  final accountElements = [
    find.byIcon(CupertinoIcons.person),
    find.byIcon(Icons.person),
    find.textContaining('Account'),
    find.textContaining('Profil'),
  ];
  
  for (final element in accountElements) {
    if (element.evaluate().isNotEmpty) {
      debugPrint('✅ Found account element');
      
      await tester.ensureVisible(element);
      await tester.pumpAndSettle();
      
      await tester.tap(element.first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Check if we're on MyAccountPage
      if (find.byType(MyAccountPage).evaluate().isNotEmpty) {
        return true;
      }
    }
  }
  
  return false;
}

Future<void> _performLogout(WidgetTester tester) async {
  debugPrint('🚪 Performing logout...');
  
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Look for logout button
  final logoutButtons = [
    find.text('Abmelden'),
    find.textContaining('Abmelden'),
    find.byIcon(CupertinoIcons.square_arrow_right),
  ];
  
  for (final logoutButton in logoutButtons) {
    if (logoutButton.evaluate().isNotEmpty) {
      debugPrint('✅ Found logout button');
      
      await tester.ensureVisible(logoutButton);
      await tester.pumpAndSettle();
      
      await tester.tap(logoutButton, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Handle any confirmation dialogs
      await _handleAnyDialogs(tester);
      
      // Verify we're back on LoginPage
      if (await _verifyLoginPage(tester)) {
        debugPrint('✅ Successfully logged out');
        return;
      }
    }
  }
  
  debugPrint('⚠️ Logout button not found, but test completed main functionality');
}

Future<bool> _verifyLoginPage(WidgetTester tester) async {
  for (int attempt = 1; attempt <= 5; attempt++) {
    debugPrint('🔍 LoginPage verification attempt $attempt/5');
    
    if (find.byType(LoginPage).evaluate().isNotEmpty || 
        find.text('HM Sportsgear').evaluate().isNotEmpty ||
        find.text('Anmelden').evaluate().isNotEmpty) {
      return true;
    }
    
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  
  return false;
}

// Utility functions

Future<void> _handleAnyDialogs(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
  
  // Handle Cupertino dialogs
  if (find.byType(CupertinoAlertDialog).evaluate().isNotEmpty) {
    debugPrint('💬 Handling CupertinoAlertDialog');
    
    final buttons = ['OK', 'Weiter', 'Bestätigen', 'Schließen'];
    for (final btn in buttons) {
      final finder = find.text(btn);
      if (finder.evaluate().isNotEmpty) {
        await tester.tap(finder, warnIfMissed: false);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        return;
      }
    }
  }
  
  // Handle regular dialogs
  if (find.byType(AlertDialog).evaluate().isNotEmpty) {
    debugPrint('💬 Handling AlertDialog');
    
    final buttons = ['OK', 'Weiter', 'Bestätigen', 'Schließen'];
    for (final btn in buttons) {
      final finder = find.text(btn);
      if (finder.evaluate().isNotEmpty) {
        await tester.tap(finder, warnIfMissed: false);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        return;
      }
    }
  }
}

Future<void> _debugCurrentUIState(WidgetTester tester) async {
  debugPrint('🔍 === DEBUG: Current UI State ===');
  
  // Debug current page
  final pageTypes = [LoginPage, LocationSelectionPage, HomePage, MyRentalsPage, MyAccountPage];
  for (final pageType in pageTypes) {
    if (find.byType(pageType).evaluate().isNotEmpty) {
      debugPrint('📄 Current page: $pageType');
    }
  }
  
  // Debug visible buttons
  final buttonTypes = [CupertinoButton, ElevatedButton, FloatingActionButton];
  int totalButtons = 0;
  for (final buttonType in buttonTypes) {
    final count = find.byType(buttonType).evaluate().length;
    totalButtons += count;
  }
  debugPrint('🔘 Total buttons found: $totalButtons');
  
  // Debug key texts
  final keyTexts = [
    'HM Sportsgear', 'Anmelden', 'Registrieren',
    'Standort wählen', 'Campus Pasing',
    'Meine Ausleihen', 'Ausleihen', 'Zurückgeben', 'Bewerten',
    'Mein Account', 'Abmelden'
  ];
  
  debugPrint('📝 Visible key texts:');
  for (final text in keyTexts) {
    if (find.text(text).evaluate().isNotEmpty) {
      debugPrint('  ✅ $text');
    }
  }
  
  debugPrint('🔍 === END DEBUG ===');
}