// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:nexventory/src/components/global/appbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 100).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        if (!mounted) return;

        // Show success popup
        // showDialog(
        //   context: context,
        //   barrierDismissible: false,
        //   barrierColor: Colors.black45,
        //   builder: (context) => _buildSuccessPopup(),
        // );

        // Redirect after 2 seconds
        await Future.delayed(const Duration(seconds: 6));
        if (!mounted) return;
        // Navigator.pop(context); // Close popup
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw AuthException("Login failed");
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.message}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid =
        emailController.text.isNotEmpty && passwordController.text.length >= 8;

    return Scaffold(
      appBar: customAppBar(context, "Login"),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated Blurry Circles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                return Stack(
                  children: [
                    _buildBlurredCircle(
                      50 + _animation.value,
                      0,
                      Colors.pinkAccent.withAlpha(30),
                    ),
                    _buildBlurredCircle(
                      250 - _animation.value,
                      100,
                      Colors.blue.withAlpha(30),
                    ),
                    _buildBlurredCircle(
                      150 - _animation.value,
                      150,
                      Colors.green.withAlpha(30),
                    ),
                  ],
                );
              },
            ),
          ),

          // Login Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.eco, color: Colors.green, size: 42),
                          SizedBox(width: 8),
                          Text(
                            "NexVentory",
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Store & Analyze without limits",
                        style: TextStyle(fontSize: 20, color: Colors.black54),
                      ),
                      const SizedBox(height: 48),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Your email address"),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration('dilerragip@gmail.com'),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Choose a password"),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        decoration: _inputDecoration('min. 8 characters')
                            .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                }),
                              ),
                            ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isFormValid ? () => login(context) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFormValid
                                ? Colors.greenAccent
                                : Colors.grey[300],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Row(
                      //   children: const [
                      //     Expanded(child: Divider()),
                      //     Padding(
                      //       padding: EdgeInsets.symmetric(horizontal: 12),
                      //       child: Text("or", style: TextStyle(fontSize: 16)),
                      //     ),
                      //     Expanded(child: Divider()),
                      //   ],
                      // ),
                      // const SizedBox(height: 30),

                      // SizedBox(
                      //   width: double.infinity,
                      //   child: OutlinedButton.icon(
                      //     icon: Image.asset(
                      //       'assets/images/google.jpg', // Your local image path
                      //       height: 24,
                      //       width: 24,
                      //     ),
                      //     label: const Text(
                      //       'Sign up with Google',
                      //       style: TextStyle(color: Colors.black),
                      //     ),
                      //     onPressed: () {},
                      //     style: OutlinedButton.styleFrom(
                      //       padding: const EdgeInsets.symmetric(
                      //         vertical: 10,
                      //         horizontal: 14,
                      //       ),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(28),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredCircle(double top, double left, Color color) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 350,
        height: 350,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withAlpha(50), // Inner color (glow)
              color.withAlpha(1), // Fades out
            ],
            radius: 0.4,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: const BorderSide(color: Colors.grey), // Default border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey), // Non-focused border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.blue,
          width: 2,
        ), // Focused border
      ),
    );
  }

  // Widget _buildSuccessPopup() {
  //   return Center(
  //     child: BackdropFilter(
  //       filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
  //       child: Container(
  //         padding: const EdgeInsets.all(24),
  //         decoration: BoxDecoration(
  //           color: const Color.fromARGB(97, 0, 0, 0),
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         width: 250,
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Image.asset(
  //               'assets/animations/success.gif',
  //               // height: 100,
  //               // width: 100,
  //             ),
  //             const SizedBox(height: 16),
  //             const Text(
  //               'Successfully Logged in',
  //               style: TextStyle(color: Colors.white, fontSize: 16),
  //               textAlign: TextAlign.center,
  //             ),
  //             const SizedBox(height: 16),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
