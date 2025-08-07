import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardScreen extends StatelessWidget {
  const OnboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.black, // Transparent to blend with curved UI
        statusBarIconBrightness:
            Brightness.light, // Light icons for dark background
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBarTheme(color:  Colors.black),
      body: SafeArea(
        child: Column(
          children: [
            // Top curved container with logo
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Curved Container
                Container(
                  height: 420,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),

                // Circular Icon
                Positioned(
                  bottom: -40,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.eco,
                        size: 40,
                        color: Color(0xFF98FB98),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const Text(
                    'NexVentory',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0C1B2C),
                      fontFamily: 'MintGrotesk',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Streamline, Track, and Grow with Intelligent Stock Control',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(),

            Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF98FB98),
                        foregroundColor: const Color(0xFF0C1B2C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(color: Colors.black, width: 1),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        "SignUp",
                        style: TextStyle(fontFamily: "MintGrotesk"),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF98FB98),
                        foregroundColor: const Color(0xFF0C1B2C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(color: Colors.black, width: 1),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(fontFamily: "MintGrotesk"),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
