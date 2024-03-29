import 'package:flutter/material.dart';
import 'package:cryptemis/home/header.dart';
import 'package:cryptemis/home/search.dart';
import 'package:cryptemis/home/options.dart';
import 'package:cryptemis/home/files.dart';
import 'package:cryptemis/settings/settings.dart';
import 'package:cryptemis/encrypt/encrypt.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  Set<String> _selectedFiles = {};
  Directory? _currentDirectory;
  int _refreshKey = 0;

// Refresh method
  void _refreshFiles() {
    setState(() {
      _refreshKey++;
    });
  }

  void _onSelectedFilesChanged(Set<String> selectedFiles) {
    setState(() {
      _selectedFiles = selectedFiles;
    });
  }

  void _onDirectoryChanged(Directory newDirectory) {
    setState(() {
      _currentDirectory = newDirectory;
    });
  }

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
              SearchSection(),
              OptionsSection(
                selectedFiles: _selectedFiles,
                refreshFiles: _refreshFiles,
                onFileSelectionChanged: _onSelectedFilesChanged,
                currentDirectory: _currentDirectory,
              ),
              Flexible(
                child: FilesSection(
                  key: ValueKey(_refreshKey),
                  onSelectedFilesChanged: _onSelectedFilesChanged,
                  onDirectoryChanged: _onDirectoryChanged,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _navigationBar(),
    );
  }

  Widget _navigationBar() {
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
            selectedItemColor: Colors.blue,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                label: 'Home',
                icon: Icon(
                  Icons.home,
                  size: 30,
                ),
              ),
              BottomNavigationBarItem(
                label: "Encrypt",
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
}
