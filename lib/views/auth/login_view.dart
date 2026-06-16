import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/theme.dart';
import '../../core/services/firebase_service.dart';
import '../home/home_view.dart';
import '../widgets/glass_container.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      if (_isRegistering) {
        await FirebaseService.instance.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await FirebaseService.instance.loginWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeView()),
      );
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll("Exception:", "").trim();
        _isLoading = false;
      });
    }
  }

  Future<void> _socialSignIn(String provider) async {
    setState(() => _isLoading = true);
    try {
      if (provider == 'google') {
        await FirebaseService.instance.signInWithGoogle();
      } else if (provider == 'apple') {
        await FirebaseService.instance.signInWithApple();
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeView()),
      );
    } catch (e) {
      setState(() {
        _errorMsg = "Social authentication failed: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkBackgroundGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branding
                Text(
                  "TraceAR",
                  textAlign: Alignment.center.x == 0.0 ? TextAlign.center : null,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontFamily: GoogleFonts.outfit().fontFamily,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Professional AR Stencil Tracing App",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Form card
                GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isRegistering ? "Create Account" : "Welcome Back",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (_errorMsg != null) ...[
                        Text(
                          _errorMsg!,
                          style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: "Email address"),
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: "Password"),
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: AppTheme.accentBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _submit,
                              child: Text(
                                _isRegistering ? "Sign Up" : "Sign In",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegistering = !_isRegistering;
                          });
                        },
                        child: Text(
                          _isRegistering
                              ? "Already have an account? Sign In"
                              : "New to TraceAR? Create account",
                          style: const TextStyle(color: AppTheme.accentCyan),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Social Sign-ins divider
                Row(
                  children: const [
                    Expanded(child: Divider(color: AppTheme.glassBorder)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text("OR CONTINUE WITH", style: TextStyle(fontSize: 10, color: Colors.white38)),
                    ),
                    Expanded(child: Divider(color: AppTheme.glassBorder)),
                  ],
                ),
                const SizedBox(height: 16),

                // Google & Apple Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                        label: const Text("Google", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _socialSignIn('google'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.apple, color: Colors.white),
                        label: const Text("Apple", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _socialSignIn('apple'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
