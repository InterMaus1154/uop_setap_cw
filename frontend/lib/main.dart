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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => InvitationCodeProvider(apiService: apiService)),
      ],
      child: MaterialApp(
        title: 'Campus Connect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const UserSelectionScreen(),
      ),
    );
  }
}
