import 'package:flutter/material.dart';

class OptionSection extends StatefulWidget {
  @override
  _OptionSectionState createState() => _OptionSectionState();
}

class _OptionSectionState extends State<OptionSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 682,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(245, 245, 245, 1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
    );
  }
}
