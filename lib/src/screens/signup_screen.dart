// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:nexventory/src/components/global/appbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isGoogleLoading = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '512925215650-av9p0e9o3ombv7b08fn357mmt1799rrh.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

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

  void signup(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'nexventory://auth/callback',
      );

      // Check if widget is still mounted before using context
      if (!mounted) return;

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup successful! Check your email to confirm.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/verify-email');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unexpected error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> signUpWithGoogle() async {
    setState(() {
      isGoogleLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          isGoogleLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }

      final supabase = Supabase.instance.client;

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (response.user != null) {
        // Optional: Check if this is a *new* user
        final createdAtString = response.user!.createdAt;
        final createdAt = DateTime.parse(createdAtString);
        final now = DateTime.now();
        final difference = now.difference(createdAt);

        if (difference.inSeconds < 10) {
          // This is a new sign-up
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome! Your account has been created.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.pushReplacementNamed(
            context,
            '/welcome',
          ); // Sign-up welcome page
        } else {
          // Already existed (optional: handle differently)
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        throw Exception('Failed to sign up with Google');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-up failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid =
        emailController.text.isNotEmpty && passwordController.text.length >= 8;

    return SafeArea(
      child: Scaffold(
        // appBar: customAppBar(context, "Signup"),
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
                        Color(0xFF98AFFB).withAlpha(30),
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
                            Icon(Icons.eco, color: Color(0xFF98AFFB), size: 42),
                            SizedBox(width: 8),
                            Text(
                              "NexVentory",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Store & Analyze without limits",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 48),

                        // Google Sign In Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: isGoogleLoading
                                ? null
                                : signUpWithGoogle,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Colors.grey),
                              backgroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isGoogleLoading) ...[
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Signing in...',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          'https://developers.google.com/identity/images/g-logo.png',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

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
                            onPressed: isFormValid
                                ? () => signup(context)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFormValid
                                  ? const Color(0xFF98AFFB)
                                  : Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'Create New Account',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ); // Change route as needed
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                color: Colors.black87,
                                fontFamily: "MintGrotesk",
                              ),
                              children: [
                                TextSpan(
                                  text: "Login",
                                  style: TextStyle(
                                    color: Color(0xFF98AFFB),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
}
