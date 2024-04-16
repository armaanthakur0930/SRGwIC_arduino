import 'package:flutter/material.dart';
import 'package:srgwic/initial.dart'; // Updated import
import 'package:srgwic/home_page.dart';

void main() async {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => InitialPage(), // Updated route to InitialPage
        '/home': (context) => HomePage(ingredientData: {'ingredientName': 'Sugar', 'weight': null}), // Updated to provide default data
      },
    );
  }
}
