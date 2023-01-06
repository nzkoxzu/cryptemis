import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disclaimer')),
      body: SingleChildScrollView(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Dependencies',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Text(
            'Application relies on dependencies. These dependencies may contain bugs or vulnerabilities that were not responsible because they are developed and maintained by third parties. ',
          ),
          Center(
            child: SelectableText.rich(TextSpan(children: [
              TextSpan(
                  text: '\nCryptemis',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text: ': \ngithub.com/nzkoxzu/cryptemis',
                  style: TextStyle(fontStyle: FontStyle.italic)),
              TextSpan(
                  text:
                      ': \ngithub.com/Denis-REMACLE/cryptopq',
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ])),
          ),
        ],
      )),
    );
  }
}
