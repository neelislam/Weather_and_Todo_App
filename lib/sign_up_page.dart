import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController(); // Mobile number is optional
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('Passwords do not match');
        return;
      }

      setState(() => _isLoading = true);
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Optional: Update user profile with display name immediately after creation
        await userCredential.user?.updateDisplayName(_usernameController.text.trim());

        _showSnackBar('Account created successfully! You can now sign in.');
        Navigator.pop(context); // Go back to Sign In page after successful sign up
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'An unknown error occurred during sign up.';
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account already exists for that email.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          default:
          // Log the actual error for debugging
            print('Firebase Auth Error: ${e.code} - ${e.message}');
            errorMessage = 'Sign up failed: ${e.message ?? 'Please try again.'}';
        }
        _showSnackBar(errorMessage);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up"),
        centerTitle: true,
      ),
      body: Center(

        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              //mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/logo/weather_icon.png',
                  width: 150, // Set a fixed width
                  height: 150, // Set a fixed height
                  fit: BoxFit.contain, // Ensure the image fits within the bounds
                ),
                SizedBox(height: 30,),
                Text('Please Register for more...',style: TextStyle(color: Colors.green,fontWeight: FontWeight.bold, fontSize: 25),),
                SizedBox(height: 20,),
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration('Username', Icons.person),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a username' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration('Email', Icons.email),
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
                SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: _inputDecoration('Password', Icons.lock),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: _inputDecoration('Confirm Password', Icons.lock_reset),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _mobileController,
                  decoration: _inputDecoration('Phone Number (Optional)', Icons.phone),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 25),
                _isLoading
                    ?  LinearProgressIndicator()
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Navigate back to sign-in
                        },
                        icon: Icon(Icons.arrow_back),
                        label:  Text("Back"),
                        style: OutlinedButton.styleFrom(
                          padding:  EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14), // Spacing between buttons
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _signUp,
                        icon: Icon(Icons.person_add),
                        label:Text("Sign Up"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black, // Text color for contrast
                          backgroundColor: Colors.lightBlue, // Distinct color for sign up
                          padding: EdgeInsets.symmetric(vertical: 14),
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

  // Helper method for consistent input decoration
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
}