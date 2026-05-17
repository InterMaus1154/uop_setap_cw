import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/friend_provider.dart';
import 'providers/location_provider.dart';
import 'providers/user_provider.dart';
import 'screens/user_selection_screen.dart';
import 'providers/invitation_code_provider.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final UserProvider? userProvider;
  final ApiService? apiService;
  final Widget? home;

  const MyApp({super.key, this.userProvider, this.apiService, this.home});

  @override
  Widget build(BuildContext context) {
    final apiService = this.apiService ?? ApiService();
    return MultiProvider(
      providers: [
        if (userProvider != null)
          ChangeNotifierProvider<UserProvider>.value(value: userProvider!)
        else
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
          create: (_) => InvitationCodeProvider(apiService: apiService),
        ),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final isDarkMode = userProvider.currentUser?.darkMode ?? false;
          return MaterialApp(
            title: 'Campus Connect',
            debugShowCheckedModeBanner: false,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: home ?? const UserSelectionScreen(),
          );
        },
      ),
    );
  }
}
