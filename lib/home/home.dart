import 'package:cryptemis/home/header.dart';
import 'package:cryptemis/home/search.dart';
import 'package:cryptemis/home/options.dart';
import 'package:cryptemis/home/files.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SingleChildScrollView(
          child: Stack(
        children: [
          Transform(
            transform: Matrix4.identity()..rotateZ(20),
            origin: const Offset(150, 50),
            child: Image.asset(
              '/Users/nzkoxzu/cryptemis/assets/images/bg_liquid.png',
              width: 200,
            ),
          ),
          Positioned(
            right: 0,
            top: 200,
            child: Transform(
              transform: Matrix4.identity()..rotateZ(20),
              origin: const Offset(180, 100),
              child: Image.asset(
                '/Users/nzkoxzu/cryptemis/assets/images/bg_liquid.png',
                width: 200,
              ),
            ),
          ),
          Column(
            children: [
              HeaderSection(),
              SearchSection(),
              OptionsSection(),
              FilesSection(),
            ],
          ),
        ],
      )),
      bottomNavigationBar: NavigationBar(),
    );
  }
}

// Bottom navbar
Widget NavigationBar() {
  return Container(
    color: Colors.grey.shade100,
    child: Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomNavigationBar(
          selectedItemColor: Colors.blue,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              label: 'Secure Filer',
              icon: Icon(
                Icons.folder,
                size: 30,
              ),
            ),
            BottomNavigationBarItem(
              label: "Encryption",
              icon: Container(
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.enhanced_encryption,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
            BottomNavigationBarItem(
              label: "Settings",
              icon: Container(
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.settings,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
