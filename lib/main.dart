import 'package:flutter/material.dart';
import 'package:food_app/pages/login_page.dart';

import 'color.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food App',
      theme: ThemeData(
        
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.airforceBlue),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}