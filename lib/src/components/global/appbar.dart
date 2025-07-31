import 'package:flutter/material.dart';

AppBar customAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.white,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new,
        size: 16,
        color: Color(0xFF0C1B2C),
      ),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF0C1B2C),
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
