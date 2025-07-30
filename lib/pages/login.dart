import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lostandfound/pages/dashboard_screen.dart';
import 'auth/signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool showPassword = false;
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  bool isGoogleLoading = false; // Add this in your state

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Login failed")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google Sign-In failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top curved blue container
              Container(
                height: 220,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -60,
                      top: -30,
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      top: 50,
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.only(top: 80.0),
                        child: Column(
                          children: [
                            Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Please login to continue...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Email field
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined),
                        hintText: 'Enter your email',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: 'Enter your password',
                        filled: true,
                        fillColor: Colors.grey[100],
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => showPassword = !showPassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Forgot Password? Click',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('or continue with'),
                    const SizedBox(height: 16),

                    // Google Sign In
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isGoogleLoading
                            ? null
                            : () async {
                                setState(() => isGoogleLoading = true);
                                await _signInWithGoogle();
                                setState(() => isGoogleLoading = false);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // primary blue color
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        child: isGoogleLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => SignUpScreen()),
                            );
                          },
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
