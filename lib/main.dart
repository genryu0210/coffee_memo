import 'package:flutter/material.dart';
import 'package:coffee_memo/screen/main_screen.dart';

void main() {
  runApp(CoffeeApp());
}

class CoffeeApp extends StatelessWidget {
  const CoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color(0xFF58C0EB), // 指定された青色を使う
        scaffoldBackgroundColor: Colors.white, // 背景色は白
        appBarTheme: AppBarTheme(
          color: Color(0xFF58C0EB), // アプリバーも同じ色
        ),
        // textTheme: TextTheme(
          // bodyText2: TextStyle(color: Colors.black),
        // ),
      ),
      home: MainScreen(),
    );
  }
}
