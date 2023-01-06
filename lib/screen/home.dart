import 'package:flutter/material.dart';
import 'package:cryptemis/screen/create_secret.dart';
import 'package:cryptemis/screen/recover_secret.dart';
import 'package:cryptemis/widget/disclaimer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const DisclaimerWidget(),
            const SizedBox(height: 20),
            Text('Cryptemis', style: TextStyle(fontSize: 48, color: Colors.white)),
            const SizedBox(height: 20),
            Text('Your new secured black box used to inform police services if necessary', style: TextStyle(fontSize: 16, color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.white,
                onPrimary: Colors.teal,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateSecretScreen()),
                );
              },
              child: const Text('Emergency button', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 20),
            Text('This is the place where we can explain the Cryptemis project and how it securely protect the data stored within encrypted container using strong cryptographic algorithms.', style: TextStyle(fontSize: 16, color: Colors.white)),
            const SizedBox(height: 20),
            Text('github.com/nzkoxzu/cryptemis', style: TextStyle(fontSize: 16, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
