import 'package:flutter/material.dart';
import 'package:coffee_memo/screen/main_screen.dart';

void main() {
  // debugPaintSizeEnabled =true;
  runApp(CoffeeApp());
}

class CoffeeApp extends StatelessWidget {
  const CoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: TextTheme(
            bodyMedium: TextStyle(
          fontFamily: 'San Francisco',
          fontSize: 16, 
        )),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF58C0EB),
          background: Colors.white,
        ),
        // primaryColor: Color(0xFF58C0EB), // 指定された青色を使う
        scaffoldBackgroundColor: Colors.white, // 背景色は白
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0
        ),
      ),
      home: MainScreen(),
    );
  }
}
