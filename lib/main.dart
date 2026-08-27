import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  
  runApp(const BookfaceApp());
}

class BookfaceApp extends StatelessWidget {
  const BookfaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bookface',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashScreen(),
    );
  }
}
