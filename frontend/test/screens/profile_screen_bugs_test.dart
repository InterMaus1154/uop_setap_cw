// Bug condition exploration tests for ProfileScreen UI bugs.
//
// **Validates: Requirements 1.5, 1.7**
//
// These tests verify the fixed profile screen behavior.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/providers/friend_provider.dart';
import 'package:frontend/screens/profile_screen.dart';

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
  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
}

class FakeFriendProvider extends ChangeNotifier implements FriendProvider {
  @override
  void clear() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

User _testUser({bool useDisplayName = false}) => User(
  userId: 1,
  firstName: 'Test',
  lastName: 'User',
  email: 'test@test.app',
  displayName: 'TestDisplay',
  useDisplayName: useDisplayName,
);

Widget _buildTestWidget({
  required FakeUserProvider userProvider,
  FakeFriendProvider? friendProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ChangeNotifierProvider<FriendProvider>.value(
        value: friendProvider ?? FakeFriendProvider(),
      ),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

void main() {
  group('Bug: Only one Save Changes button when editing', () {
    testWidgets('should render exactly one Save Changes button in edit mode', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final userProvider = FakeUserProvider(_testUser());
      await tester.pumpWidget(_buildTestWidget(userProvider: userProvider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap "Edit Profile" to open the edit form
      final editButton = find.text('Edit Profile');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pump();

      // Should have exactly one Save Changes button
      final saveButtons = find.widgetWithText(ElevatedButton, 'Save Changes');
      expect(
        saveButtons,
        findsOneWidget,
        reason: 'Should render exactly one Save Changes button in edit mode.',
      );
    });
  });

  group('Bug: _showDisplayName not overwritten on rebuild', () {
    testWidgets(
      'toggle state should survive provider notification without being overwritten',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Start with useDisplayName = true
        final userProvider = FakeUserProvider(_testUser(useDisplayName: true));
        await tester.pumpWidget(_buildTestWidget(userProvider: userProvider));
        await tester.pump();

        // Open edit form
        await tester.tap(find.text('Edit Profile'));
        await tester.pump();

        // Find the "Display Name" toggle — it should be selected (blue bg)
        final displayNameToggle = find.text('Display Name');
        expect(displayNameToggle, findsOneWidget);

        // Simulate provider notification with useDisplayName=false
        // Local state should NOT be overwritten
        userProvider.updateUser(_testUser(useDisplayName: false));
        await tester.pump();

        // The "Display Name" toggle should still appear selected
        // because local state is preserved across rebuilds.
        // We verify by checking the toggle container's decoration color.
        final toggleContainer = find.ancestor(
          of: find.text('Display Name'),
          matching: find.byType(Container),
        );
        expect(toggleContainer, findsWidgets);

        // Find the immediate Container parent of the "Display Name" text
        final containers = toggleContainer.evaluate().toList();
        bool foundBlueToggle = false;
        for (final element in containers) {
          final widget = element.widget;
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration as BoxDecoration;
            if (decoration.color == Colors.blue[400]) {
              foundBlueToggle = true;
              break;
            }
          }
        }

        expect(
          foundBlueToggle,
          isTrue,
          reason:
              'Display Name toggle should remain selected (blue) after provider '
              'notification. Local state should not be overwritten by build().',
        );
      },
    );
  });
}
