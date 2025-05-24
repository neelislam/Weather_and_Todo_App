import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // For theme access

import 'sign_up_page.dart';
import 'weather_home.dart'; // <-- IMPORTANT: Import weather_home.dart to access ThemeProvider

class SignInPage extends StatefulWidget {
  // Add these two properties
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const SignInPage({
    super.key,
    required this.isDarkMode, // Make them required
    required this.toggleTheme, // Make them required
  });

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // If sign-in is successful, the StreamBuilder in main.dart will automatically
        // detect the authenticated user and navigate to WeatherApp.
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'An unknown error occurred.';
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found for that email. Please sign up.';
            break;
          case 'wrong-password':
            errorMessage = 'Wrong password provided for that user.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          case 'user-disabled':
            errorMessage = 'This user account has been disabled.';
            break;
          default:
          // Log the actual error for debugging
            print('Firebase Auth Error: ${e.code} - ${e.message}');
            errorMessage = 'Sign in failed: ${e.message ?? 'Please try again.'}';
        }
        _showSnackBar(errorMessage);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      // StreamBuilder in main.dart will handle navigation to WeatherApp.
    } catch (e) {
      // Log the error for debugging
      print('Guest Sign In Error: $e');
      _showSnackBar('Failed to sign in as guest: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode for dynamic styling
    // Now ThemeProvider is accessed via the weather_home.dart import
    // This line is no longer needed here as isDarkMode is passed via widget
    // final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;


    return Scaffold(
      appBar: AppBar(
        title:  Text("Sign In"),
        centerTitle: true,
        actions: [
          IconButton(
            // Use widget.isDarkMode and widget.toggleTheme directly
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Center( // Center the content on the screen
        child: SingleChildScrollView(
          padding:  EdgeInsets.all(24.0), // Consistent padding
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              children: [
                // Simplified Image.network without loadingBuilder and errorBuilder
                Image.asset(
                  'lib/logo/weather_icon.png',
                  width: 150, // Set a fixed width
                  height: 150, // Set a fixed height
                  fit: BoxFit.contain, // Ensure the image fits within the bounds
                ),
                SizedBox(height: 20), // Spacing after image
                 Text(
                  'Welcome To Weather App',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 24, // Increased font size for welcome text
                    fontWeight: FontWeight.bold,
                  ),
                ),
                 SizedBox(height: 40), // Spacing from top
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon:  Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    // Use widget.isDarkMode here
                    fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                 SizedBox(height: 20), // Spacing between fields
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon:  Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    // Use widget.isDarkMode here
                    fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                 SizedBox(height: 30), // Spacing before buttons
                _isLoading
                    ?  LinearProgressIndicator() // Show loading indicator
                    : Column(
                  children: [
                    SizedBox(
                      width: double.infinity, // Make button full width
                      child: ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          // Use widget.isDarkMode here
                          foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
                          backgroundColor: widget.isDarkMode ? Colors.blueAccent : Colors.lightBlue,
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 5, // Add a subtle shadow
                        ),
                        child:  Text(
                          "Sign In",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 15), // Spacing between buttons
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton( // Use OutlinedButton for secondary action
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>  SignUpPage()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color, // Inherit text color
                          side: BorderSide(color: Theme.of(context).colorScheme.primary), // Border color
                          padding:  EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:  Text(
                          "Create Account",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                     SizedBox(height: 25), // Spacing for OR divider
                    Row(
                      children: [
                         Expanded(child: Divider()),
                        Padding(
                          padding:  EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            "OR",
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                            ),
                          ),
                        ),
                         Expanded(child: Divider()),
                      ],
                    ),
                    SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _signInAsGuest,
                        icon: Icon(Icons.person_outline),
                        label: Text(
                          "Continue as Guest",
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black, // Always black for guest button text
                          backgroundColor: Colors.yellow, // Distinct color for guest login
                          padding:  EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 5,
                        ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
