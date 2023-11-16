import 'package:cryptemis/home/home.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext) {
    return MaterialApp(
      title: 'Cryptemis',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
