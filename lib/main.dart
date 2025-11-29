import 'package:flutter/material.dart';
import 'package:your_app_name/screen/task_page.dart';
import 'package:your_app_name/screen/members_page.dart';
import 'screen/auth/login_screen.dart';
import 'screen/auth/register_screen.dart';
import 'screen/auth/verification_screen.dart';
import 'screen/not_found_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planner Client',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const TasksPage());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (context) => const RegisterScreen());
          case '/tasks':
            return MaterialPageRoute(builder: (context) => const TasksPage());
          case '/members':
            return MaterialPageRoute(builder: (context) => const MembersPage());
          case '/verify':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => VerificationScreen(
                username: args?['username'] ?? '',
              ),
            );
          default:
            return MaterialPageRoute(builder: (context) => const NotFoundScreen());
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }
}