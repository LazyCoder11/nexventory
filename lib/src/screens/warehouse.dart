import 'package:flutter/material.dart';

class Warehouse extends StatelessWidget {
  const Warehouse({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: Text("Coming Soon", style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }
}
