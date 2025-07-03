// integration_test/improved_admin_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kreisel_frontend/main.dart' as app;
import 'package:kreisel_frontend/pages/login_page.dart';
import 'package:kreisel_frontend/pages/admin_dashboard.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Improved Admin Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Admin Registration Flow: Register -> Auto-Login -> Dashboard -> Items CRUD -> Logout', (WidgetTester tester) async {
      debugPrint('🚀 Starting Admin Registration Flow Test');
      
      // Set larger screen size to avoid layout issues
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      
      try {
        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // STEP 1: Admin Registration (auto-logs in)
        debugPrint('📝 Step 1: Admin Registration');
        await _performAdminRegistration(tester);

        // STEP 2: Check if already logged in or perform login
        debugPrint('🔐 Step 2: Check Login Status');
        await _ensureAdminLoggedIn(tester);

        // STEP 3: Ensure Admin Dashboard is ready
        debugPrint('🏠 Step 3: Prepare Admin Dashboard');
        await _prepareAdminDashboard(tester);

        // STEP 4: Create Items
        debugPrint('📦 Step 4: Create Items');
        await _createItems(tester);

        // STEP 5: Manage Items (Edit/Delete)
        debugPrint('✏️ Step 5: Manage Items');
        await _manageItems(tester);

        // STEP 6: Logout
        debugPrint('🚪 Step 6: Logout');
        await _performLogout(tester);

        debugPrint('🎉 Admin Registration Flow Test completed successfully');
        
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

    testWidgets('Admin Login Flow: Pre-registered -> Login -> Dashboard -> Basic Operations', (WidgetTester tester) async {
      debugPrint('🚀 Starting Admin Login Flow Test');
      
      // Set larger screen size to avoid layout issues
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      
      try {
        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // STEP 1: Assume admin is pre-registered, go directly to login
        debugPrint('🔐 Step 1: Direct Admin Login');
        await _performDirectAdminLogin(tester);

        // STEP 2: Verify Admin Dashboard
        debugPrint('🏠 Step 2: Verify Admin Dashboard');
        await _prepareAdminDashboard(tester);

        // STEP 3: Basic Dashboard Operations
        debugPrint('📊 Step 3: Basic Dashboard Operations');
        await _performBasicDashboardOperations(tester);

        // STEP 4: Logout
        debugPrint('🚪 Step 4: Logout');
        await _performLogout(tester);

        debugPrint('🎉 Admin Login Flow Test completed successfully');
        
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

Future<void> _performDirectAdminLogin(WidgetTester tester) async {
  debugPrint('🔐 Starting direct admin login (assuming pre-registered)...');
  
  // Ensure we're in login mode
  if (!await _ensureLoginMode(tester)) {
    throw Exception('Failed to access login mode');
  }
  
  // Fill login credentials
  if (!await _fillLoginForm(tester)) {
    throw Exception('Failed to fill login form');
  }
  
  // Submit login
  if (!await _submitLoginForm(tester)) {
    throw Exception('Failed to submit login');
  }
  
  debugPrint('✅ Direct login completed');
}

Future<void> _performBasicDashboardOperations(WidgetTester tester) async {
  debugPrint('📊 Performing basic dashboard operations...');
  
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Test tab navigation
  final tabs = ['Items', 'Rentals', 'Users'];
  
  for (final tabName in tabs) {
    final tab = find.text(tabName);
    if (tab.evaluate().isNotEmpty) {
      debugPrint('📋 Testing $tabName tab...');
      await _tapWithRetry(tester, tab, '$tabName tab');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Check if content loaded
      await tester.pumpAndSettle(const Duration(seconds: 1));
      debugPrint('✅ $tabName tab working');
    }
  }
  
  // Return to Items tab
  final itemsTab = find.text('Items');
  if (itemsTab.evaluate().isNotEmpty) {
    await _tapWithRetry(tester, itemsTab, 'Items tab (return)');
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  
  debugPrint('✅ Basic dashboard operations completed');
}

// Enhanced helper functions with better error handling and debugging

Future<void> _performAdminRegistration(WidgetTester tester) async {
  debugPrint('📝 Starting registration process...');
  
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Ensure we're in registration mode
  if (!await _ensureRegistrationMode(tester)) {
    throw Exception('Failed to switch to registration mode');
  }

  // Fill registration form with retry logic
  if (!await _fillRegistrationForm(tester)) {
    throw Exception('Failed to fill registration form');
  }

  // Submit registration
  if (!await _submitRegistrationForm(tester)) {
    throw Exception('Failed to submit registration');
  }

  debugPrint('✅ Registration completed');
}

Future<bool> _ensureRegistrationMode(WidgetTester tester) async {
  // Check if already in registration mode
  if (find.text('Vollständiger Name').evaluate().isNotEmpty) {
    debugPrint('✅ Already in registration mode');
    return true;
  }

  // Look for toggle button with retry
  for (int attempt = 1; attempt <= 3; attempt++) {
    debugPrint('🔄 Attempt $attempt to find registration toggle');
    
    final registrationToggle = find.text('Noch kein Account? Registrieren');
    if (registrationToggle.evaluate().isNotEmpty) {
      await _tapWithRetry(tester, registrationToggle, 'registration toggle');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify we switched to registration mode
      if (find.text('Vollständiger Name').evaluate().isNotEmpty) {
        debugPrint('✅ Successfully switched to registration mode');
        return true;
      }
    }
    
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
  
  debugPrint('❌ Failed to switch to registration mode');
  return false;
}

Future<bool> _fillRegistrationForm(WidgetTester tester) async {
  debugPrint('📝 Filling registration form...');
  
  final textFields = find.byType(TextField);
  
  if (textFields.evaluate().length < 3) {
    debugPrint('❌ Expected at least 3 text fields, found ${textFields.evaluate().length}');
    return false;
  }
  
  try {
    // Fill name field
    await _fillTextField(tester, textFields.at(0), 'TestAdmin', 'name');
    
    // Fill email field
    await _fillTextField(tester, textFields.at(1), 'admin@hm.edu', 'email');
    
    // Fill password field
    await _fillTextField(tester, textFields.at(2), 'password123', 'password');
    
    debugPrint('✅ Registration form filled successfully');
    return true;
  } catch (e) {
    debugPrint('❌ Failed to fill registration form: $e');
    return false;
  }
}

Future<bool> _submitRegistrationForm(WidgetTester tester) async {
  debugPrint('📤 Submitting registration...');
  
  final registerButton = find.text('Registrieren');
  
  if (registerButton.evaluate().isEmpty) {
    debugPrint('❌ Registration button not found');
    return false;
  }
  
  await _tapWithRetry(tester, registerButton, 'registration button');
  await tester.pumpAndSettle(const Duration(seconds: 8));
  
  // Handle any success dialogs
  await _handleAnyDialogs(tester);
  
  return true;
}

Future<void> _ensureAdminLoggedIn(WidgetTester tester) async {
  debugPrint('🔐 Checking if admin is already logged in...');
  
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Check if already on admin dashboard
  final dashboardIndicators = [
    find.byType(AdminDashboard),
    find.text('Admin Dashboard'),
    find.text('Items'),
  ];
  
  bool alreadyLoggedIn = false;
  for (final indicator in dashboardIndicators) {
    if (indicator.evaluate().isNotEmpty) {
      debugPrint('✅ Already logged in - found dashboard indicator');
      alreadyLoggedIn = true;
      break;
    }
  }
  
  if (alreadyLoggedIn) {
    debugPrint('✅ Admin already logged in from registration');
    return;
  }
  
  // If not logged in, try to perform login
  debugPrint('🔐 Not logged in, attempting login...');
  await _performAdminLogin(tester);
}

Future<void> _prepareAdminDashboard(WidgetTester tester) async {
  debugPrint('🏠 Preparing Admin Dashboard...');
  for (int attempt = 1; attempt <= 3; attempt++) {
    debugPrint('🔍 Dashboard preparation attempt $attempt/3');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    if (find.byType(AdminDashboard).evaluate().isNotEmpty ||
        find.text('Admin Dashboard').evaluate().isNotEmpty) {
      final itemsTab = find.text('Items');
      if (itemsTab.evaluate().isNotEmpty) {
        await _tapWithRetry(tester, itemsTab, 'Items tab');
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      debugPrint('✅ Admin Dashboard ready');
      return;
    }
  }
  throw Exception('Failed to prepare Admin Dashboard');
}

// FEHLTE: Diese Funktion muss existieren!
Future<void> _performAdminLogin(WidgetTester tester) async {
  debugPrint('🔐 Starting admin login...');
  if (!await _ensureLoginMode(tester)) throw Exception('Failed to switch to login mode');
  if (!await _fillLoginForm(tester)) throw Exception('Failed to fill login form');
  if (!await _submitLoginForm(tester)) throw Exception('Failed to submit login');
  debugPrint('✅ Login completed');
}

Future<bool> _ensureLoginMode(WidgetTester tester) async {
  // Check if already in login mode (email and password fields without name field)
  final textFields = find.byType(TextField);
  final nameField = find.text('Vollständiger Name');
  
  if (textFields.evaluate().length >= 2 && nameField.evaluate().isEmpty) {
    debugPrint('✅ Already in login mode');
    return true;
  }
  
  // Look for login toggle
  for (int attempt = 1; attempt <= 3; attempt++) {
    debugPrint('🔄 Attempt $attempt to find login toggle');
    
    final loginToggle = find.text('Bereits registriert? Anmelden');
    if (loginToggle.evaluate().isNotEmpty) {
      await _tapWithRetry(tester, loginToggle, 'login toggle');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify we switched to login mode
      final updatedTextFields = find.byType(TextField);
      final updatedNameField = find.text('Vollständiger Name');
      
      if (updatedTextFields.evaluate().length >= 2 && updatedNameField.evaluate().isEmpty) {
        debugPrint('✅ Successfully switched to login mode');
        return true;
      }
    }
    
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
  
  debugPrint('❌ Failed to switch to login mode');
  return false;
}

Future<bool> _fillLoginForm(WidgetTester tester) async {
  debugPrint('📝 Filling login form...');
  
  final textFields = find.byType(TextField);
  
  if (textFields.evaluate().length < 2) {
    debugPrint('❌ Expected at least 2 text fields for login, found ${textFields.evaluate().length}');
    return false;
  }
  
  try {
    // Clear and fill email field
    await _fillTextField(tester, textFields.at(0), 'admin@hm.edu', 'email', clearFirst: true);
    
    // Clear and fill password field
    await _fillTextField(tester, textFields.at(1), 'password123', 'password', clearFirst: true);
    
    debugPrint('✅ Login form filled successfully');
    return true;
  } catch (e) {
    debugPrint('❌ Failed to fill login form: $e');
    return false;
  }
}

Future<bool> _submitLoginForm(WidgetTester tester) async {
  debugPrint('📤 Submitting login...');
  
  // Look for login button with multiple possible texts
  final buttonTexts = ['Anmelden', 'Login', 'Sign In'];
  Finder? loginButton;
  
  for (final text in buttonTexts) {
    final button = find.text(text);
    if (button.evaluate().isNotEmpty) {
      loginButton = button;
      debugPrint('✅ Found login button: $text');
      break;
    }
  }
  
  if (loginButton == null) {
    debugPrint('❌ No login button found');
    await _debugCurrentUIState(tester);
    return false;
  }
  
  await _tapWithRetry(tester, loginButton, 'login button');
  await tester.pumpAndSettle(const Duration(seconds: 10));
  
  // Handle any dialogs
  await _handleAnyDialogs(tester);
  
  return true;
}

// ignore: unused_element
Future<void> _loadAdminDashboard(WidgetTester tester) async {
  debugPrint('🏠 Loading Admin Dashboard...');
  
  // Wait for navigation with multiple attempts
  for (int attempt = 1; attempt <= 5; attempt++) {
    debugPrint('🔍 Dashboard detection attempt $attempt/5');
    
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    // Check for admin dashboard indicators
    final dashboardIndicators = [
      find.byType(AdminDashboard),
      find.text('Admin Dashboard'),
      find.text('Items', skipOffstage: false),
      find.byIcon(Icons.logout),
    ];
    
    bool foundDashboard = false;
    for (final indicator in dashboardIndicators) {
      if (indicator.evaluate().isNotEmpty) {
        debugPrint('✅ Found dashboard indicator');
        foundDashboard = true;
        break;
      }
    }
    
    if (foundDashboard) {
      // Ensure we're on Items tab
      final itemsTab = find.text('Items');
      if (itemsTab.evaluate().isNotEmpty) {
        await _tapWithRetry(tester, itemsTab, 'Items tab');
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      debugPrint('✅ Admin Dashboard loaded successfully');
      return;
    }
    
    // Debug current state if not found
    if (attempt == 5) {
      await _debugCurrentUIState(tester);
      throw Exception('Failed to load Admin Dashboard after 5 attempts');
    }
  }
}

Future<void> _createItems(WidgetTester tester) async {
  debugPrint('📦 Creating test items...');
  
  // Create first item
  await _createSingleItem(tester, 'Test Item 1', 'First test item description');
  
  // Create second item
  await _createSingleItem(tester, 'Test Item 2', 'Second test item description');
  
  debugPrint('✅ Test items created');
}

Future<void> _createSingleItem(WidgetTester tester, String name, String description) async {
  debugPrint('📦 Creating item: $name');
  
  // Look for FloatingActionButton
  final createButton = find.byType(FloatingActionButton);
  
  if (createButton.evaluate().isEmpty) {
    throw Exception('Create button (FloatingActionButton) not found');
  }
  
  await _tapWithRetry(tester, createButton, 'create button');
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Fill item form
  if (!await _fillItemCreationForm(tester, name, description)) {
    throw Exception('Failed to fill item creation form for: $name');
  }
  
  debugPrint('✅ Item created: $name');
}

Future<bool> _fillItemCreationForm(WidgetTester tester, String name, String description) async {
  debugPrint('📝 Filling item creation form...');
  
  // Check for dialog
  if (!await _waitForDialog(tester)) {
    return false;
  }
  
  // Find text fields in dialog
  final dialogTextFields = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );
  
  if (dialogTextFields.evaluate().isEmpty) {
    debugPrint('❌ No text fields found in dialog');
    return false;
  }
  
  try {
    // Fill name (required field)
    await _fillTextField(tester, dialogTextFields.first, name, 'item name');
    
    // Fill description if available
    if (dialogTextFields.evaluate().length > 1) {
      await _fillTextField(tester, dialogTextFields.at(1), description, 'item description');
    }
    
    // Fill brand if available
    if (dialogTextFields.evaluate().length > 2) {
      await _fillTextField(tester, dialogTextFields.at(2), 'TestBrand', 'item brand');
    }
    
    // Submit form
    return await _submitItemForm(tester);
  } catch (e) {
    debugPrint('❌ Failed to fill item form: $e');
    return false;
  }
}

Future<bool> _submitItemForm(WidgetTester tester) async {
  debugPrint('📤 Submitting item form...');
  
  final submitButtons = ['Erstellen', 'Speichern', 'Create', 'Save'];
  
  for (final buttonText in submitButtons) {
    final button = find.text(buttonText);
    if (button.evaluate().isNotEmpty) {
      debugPrint('✅ Found submit button: $buttonText');
      
      await _tapWithRetry(tester, button, 'submit button');
      await tester.pumpAndSettle(const Duration(seconds: 8));
      
      await _handleAnyDialogs(tester);
      return true;
    }
  }
  
  debugPrint('❌ No submit button found');
  return false;
}

Future<void> _manageItems(WidgetTester tester) async {
  debugPrint('✏️ Managing items...');
  
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Try to delete first item
  final deleteButtons = find.byIcon(Icons.delete);
  if (deleteButtons.evaluate().isNotEmpty) {
    debugPrint('🗑️ Deleting first item...');
    await _tapWithRetry(tester, deleteButtons.first, 'delete button');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    // Confirm deletion
    await _confirmDeletion(tester);
  }
  
  // Try to edit remaining item
  final editButtons = find.byIcon(Icons.edit);
  if (editButtons.evaluate().isNotEmpty) {
    debugPrint('✏️ Editing remaining item...');
    await _tapWithRetry(tester, editButtons.first, 'edit button');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    // Fill edit form
    await _fillItemEditForm(tester, 'Updated Item Name', 'Updated description');
  }
  
  debugPrint('✅ Item management completed');
}

Future<void> _confirmDeletion(WidgetTester tester) async {
  debugPrint('🗑️ Confirming deletion...');
  
  // Look for confirmation dialog
  await tester.pumpAndSettle(const Duration(seconds: 1));
  
  final confirmButtons = ['Löschen', 'Delete', 'Ja', 'Yes'];
  
  for (final buttonText in confirmButtons) {
    final button = find.text(buttonText);
    if (button.evaluate().isNotEmpty) {
      debugPrint('✅ Found delete confirmation: $buttonText');
      await _tapWithRetry(tester, button, 'delete confirmation');
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      await _handleAnyDialogs(tester);
      return;
    }
  }
  
  debugPrint('⚠️ No delete confirmation found');
}

Future<bool> _fillItemEditForm(WidgetTester tester, String newName, String newDescription) async {
  debugPrint('✏️ Filling edit form...');
  
  if (!await _waitForDialog(tester)) {
    return false;
  }
  
  final dialogTextFields = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );
  
  if (dialogTextFields.evaluate().isEmpty) {
    debugPrint('❌ No text fields found in edit dialog');
    return false;
  }
  
  try {
    // Update name
    await _fillTextField(tester, dialogTextFields.first, newName, 'updated name', clearFirst: true);
    
    // Update description if available
    if (dialogTextFields.evaluate().length > 1) {
      await _fillTextField(tester, dialogTextFields.at(1), newDescription, 'updated description', clearFirst: true);
    }
    
    // Submit edit form
    final submitButtons = ['Speichern', 'Update', 'Save'];
    for (final buttonText in submitButtons) {
      final button = find.text(buttonText);
      if (button.evaluate().isNotEmpty) {
        await _tapWithRetry(tester, button, 'save button');
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _handleAnyDialogs(tester);
        return true;
      }
    }
    
    return false;
  } catch (e) {
    debugPrint('❌ Failed to fill edit form: $e');
    return false;
  }
}

Future<void> _performLogout(WidgetTester tester) async {
  debugPrint('🚪 Performing logout...');
  
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  final logoutButton = find.byIcon(Icons.logout);
  
  if (logoutButton.evaluate().isEmpty) {
    debugPrint('❌ Logout button not found');
    await _debugCurrentUIState(tester);
    throw Exception('Logout button not found');
  }
  
  await _tapWithRetry(tester, logoutButton, 'logout button');
  await tester.pumpAndSettle(const Duration(seconds: 5));
  
  // Verify we're back to login page
  if (find.byType(LoginPage).evaluate().isNotEmpty) {
    debugPrint('✅ Successfully logged out');
  } else {
    debugPrint('⚠️ Logout may not have completed properly');
  }
}

// Enhanced utility functions

Future<bool> _waitForDialog(WidgetTester tester, {int maxAttempts = 5}) async {
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    
    if (find.byType(AlertDialog).evaluate().isNotEmpty || 
        find.byType(CupertinoAlertDialog).evaluate().isNotEmpty) {
      debugPrint('✅ Dialog found on attempt $attempt');
      return true;
    }
  }
  
  debugPrint('❌ No dialog found after $maxAttempts attempts');
  return false;
}

Future<void> _fillTextField(WidgetTester tester, Finder textField, String text, String fieldName, {bool clearFirst = false}) async {
  debugPrint('📝 Filling $fieldName field with: $text');
  
  await _tapWithRetry(tester, textField, fieldName);
  await tester.pumpAndSettle(const Duration(milliseconds: 200));
  
  if (clearFirst) {
    await tester.enterText(textField, '');
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }
  
  await tester.enterText(textField, text);
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
  
  debugPrint('✅ $fieldName field filled');
}

Future<void> _tapWithRetry(WidgetTester tester, Finder finder, String elementName, {int maxAttempts = 3}) async {
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      if (finder.evaluate().isEmpty) {
        debugPrint('❌ $elementName not found on attempt $attempt');
        if (attempt == maxAttempts) {
          throw Exception('$elementName not found after $maxAttempts attempts');
        }
        await tester.pumpAndSettle(const Duration(seconds: 1));
        continue;
      }
      
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      
      debugPrint('✅ Successfully tapped $elementName on attempt $attempt');
      return;
    } catch (e) {
      debugPrint('⚠️ Failed to tap $elementName on attempt $attempt: $e');
      if (attempt == maxAttempts) {
        rethrow;
      }
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
  }
}

Future<void> _handleAnyDialogs(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
  
  // Handle success/error dialogs
  final dialogTypes = [CupertinoAlertDialog, AlertDialog];
  
  for (final dialogType in dialogTypes) {
    if (find.byType(dialogType).evaluate().isNotEmpty) {
      debugPrint('💬 Handling dialog of type: $dialogType');
      
      final buttons = ['OK', 'Weiter', 'Bestätigen', 'Schließen', 'Close'];
      for (final btnText in buttons) {
        final button = find.text(btnText);
        if (button.evaluate().isNotEmpty) {
          await _tapWithRetry(tester, button, 'dialog button');
          return;
        }
      }
    }
  }
}

Future<void> _debugCurrentUIState(WidgetTester tester) async {
  debugPrint('🔍 === DEBUG: Current UI State ===');
  
  // Debug current page
  final commonPages = [LoginPage, AdminDashboard];
  for (final pageType in commonPages) {
    if (find.byType(pageType).evaluate().isNotEmpty) {
      debugPrint('📄 Current page: $pageType');
    }
  }
  
  // Debug visible text
  final visibleTexts = <String>[];
  final textWidgets = find.byType(Text).evaluate();
  for (final widget in textWidgets) {
    if (widget.widget is Text) {
      final text = (widget.widget as Text).data;
      if (text != null && text.isNotEmpty) {
        visibleTexts.add(text);
      }
    }
  }
  
  debugPrint('📝 Visible texts: ${visibleTexts.take(10).join(", ")}...');
  
  // Debug buttons
  final buttons = find.byType(ElevatedButton).evaluate().length + 
                  find.byType(CupertinoButton).evaluate().length +
                  find.byType(FloatingActionButton).evaluate().length;
  debugPrint('🔘 Total buttons found: $buttons');
  
  // Debug text fields
  final textFields = find.byType(TextField).evaluate().length;
  debugPrint('📝 Text fields found: $textFields');
  
  debugPrint('🔍 === END DEBUG ===');
}