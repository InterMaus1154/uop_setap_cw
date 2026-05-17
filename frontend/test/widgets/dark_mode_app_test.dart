import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/providers/friend_provider.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/main.dart';

class FakeUserProvider extends ChangeNotifier implements UserProvider {
  User? _currentUser;

  FakeUserProvider(this._currentUser);

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  bool get isLoading => false;

  @override
  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  @override
  Future<void> login(String email) async {}
  @override
  Future<void> loginWithCode(String code) async {}

  @override
  Future<void> logout() async {}
}

User _testUser({bool darkMode = false}) => User(
  userId: 1,
  firstName: 'Test',
  lastName: 'User',
  email: 'test@test.app',
  displayName: 'TestDisplay',
  useDisplayName: false,
  isActive: true,
  darkMode: darkMode,
);

class MockApiService extends ApiService {
  bool updateCalled = false;
  bool getCalled = false;
  @override
  Future<void> updateUserProfile({
    required String fname,
    required String lname,
    String? displayName,
    required bool useDisplayName,
    required bool useDarkMode,
  }) async {
    // simulate success
    updateCalled = true;
    return;
  }

  @override
  Future<User> getUserById(int userId) async {
    getCalled = true;
    // return a user with darkMode true to simulate backend update
    return _testUser(darkMode: true);
  }

  Future<int> getMyPinCount() async => 0;

  @override
  Future<List<User>> getFriends() async => [];
  // @override
  // Future<List> getIncomingRequests() async => [];
  // @override
  // Future<List> getSentRequests() async => [];
}

void main() {
  testWidgets('Changing dark mode in settings saves and updates app theme', (
    WidgetTester tester,
  ) async {
    final userProvider = FakeUserProvider(_testUser(darkMode: false));
    final mockApi = MockApiService();

    // Build a small app that uses UserProvider to select themeMode, and uses ProfileScreen as home
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ChangeNotifierProvider<FriendProvider>.value(
            value: FriendProvider(apiService: mockApi),
          ),
        ],
        child: Builder(
          builder: (context) {
            final isDark =
                context.watch<UserProvider>().currentUser?.darkMode ?? false;
            return MaterialApp(
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              home: ProfileScreen(apiService: mockApi),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open edit form
    final editFinder = find.text('Edit Profile');
    expect(editFinder, findsOneWidget);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();

    // Tap the 'On' dark mode toggle (using text 'On')
    final onText = find.text('On');
    expect(onText, findsWidgets);
    await tester.tap(onText.first);
    await tester.pumpAndSettle();

    // Press Save Changes
    final saveButton = find.widgetWithText(ElevatedButton, 'Save Changes');
    expect(saveButton, findsOneWidget);
    // Ensure form fields are populated (validators require non-empty names)
    final firstNameField = find.byType(TextFormField).at(0);
    final lastNameField = find.byType(TextFormField).at(1);
    await tester.enterText(firstNameField, 'Test');
    await tester.enterText(lastNameField, 'User');
    await tester.pump();
    // Ensure the Save button is visible before tapping (scroll if needed)
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);

    // Allow async save and provider update to complete
    await tester.pumpAndSettle();

    // Ensure API was invoked
    expect(
      mockApi.updateCalled,
      isTrue,
      reason: 'updateUserProfile should be called',
    );
    expect(mockApi.getCalled, isTrue, reason: 'getUserById should be called');

    // After saving, provider should have been updated to darkMode true
    expect(userProvider.currentUser?.darkMode, isTrue);

    // And the MaterialApp should now be using dark theme
    final MaterialApp appWidget = tester.widget(find.byType(MaterialApp));
    expect(appWidget.themeMode, equals(ThemeMode.dark));
  });

  testWidgets('E2E: toggling dark mode via MyApp updates app theme', (
    WidgetTester tester,
  ) async {
    final fakeProvider = FakeUserProvider(_testUser(darkMode: false));
    final mockApi = MockApiService();

    await tester.pumpWidget(
      MyApp(userProvider: fakeProvider, apiService: mockApi, home: ProfileScreen(apiService: mockApi)),
    );

    await tester.pumpAndSettle();

    // Open edit
    final edit = find.text('Edit Profile');
    expect(edit, findsOneWidget);
    await tester.tap(edit);
    await tester.pumpAndSettle();

    // Turn on dark
    final onText = find.text('On');
    expect(onText, findsWidgets);
    await tester.tap(onText.first);
    await tester.pump();

    // fill required fields
    final first = find.byType(TextFormField).at(0);
    final last = find.byType(TextFormField).at(1);
    await tester.enterText(first, 'Test');
    await tester.enterText(last, 'User');
    await tester.pump();

    // Save
    final save = find.widgetWithText(ElevatedButton, 'Save Changes');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    // API called and provider updated
    expect(mockApi.updateCalled, isTrue);
    expect(mockApi.getCalled, isTrue);
    expect(fakeProvider.currentUser?.darkMode, isTrue);

    // MaterialApp should be using dark theme
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, equals(ThemeMode.dark));
  });
}
