import 'package:flutter/material.dart';
import 'package:cryptemis/home/home.dart';
import 'package:cryptemis/encrypt/header.dart';
import 'package:cryptemis/encrypt/options.dart';
import 'package:cryptemis/settings/settings.dart';

class EncryptPage extends StatelessWidget {
  const EncryptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Stack(
        children: [
          Transform(
            transform: Matrix4.identity()..rotateZ(20),
            origin: const Offset(150, 50),
            child: Image.asset(
              'assets/images/bg_liquid.png',
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
                'assets/images/bg_liquid.png',
                width: 200,
              ),
            ),
          ),
          Column(
            children: [
              HeaderSection(),
              OptionSection(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _navigationBar(context),
    );
  }
}

Widget _navigationBar(BuildContext context) {
  return Container(
    color: Colors.grey.shade100,
    child: Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          selectedItemColor: Colors.blue,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              label: 'Home',
              icon: Container(
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.home,
                  size: 20,
                ),
              ),
            ),
            BottomNavigationBarItem(
              label: "Encrypt",
              icon: const Icon(
                Icons.enhanced_encryption,
                size: 30,
                color: Colors.blue,
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
                ),
              ),
            ),
          ],
          onTap: (index) {
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EncryptPage()),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            }
          },
        ),
      ),
    ),
  );
}
