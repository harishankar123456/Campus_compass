import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String selectedRole = 'Student';

  void showPopup(BuildContext context, String message, bool isSuccess) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87, // Darker background for popup
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isSuccess ? 'Success' : 'Error',
            style: TextStyle(
              color: isSuccess ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void registerUser(BuildContext context) async {
    if (passwordController.text != confirmPasswordController.text) {
      showPopup(context, 'Passwords do not match', false);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );

    try {
      await createUserWithEmailAndPassword(context);
      Navigator.of(context).pop();
      showPopup(context,
          'Registration successful! Please verify your email to log in.', true);
    } catch (e) {
      Navigator.of(context).pop();
      showPopup(context, 'Registration failed: ${e.toString()}', false);
    }
  }

  Future<void> createUserWithEmailAndPassword(BuildContext context) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateProfile(displayName: usernameController.text.trim());
        await user.reload();
        user = FirebaseAuth.instance.currentUser;
      }

      await userCredential.user?.sendEmailVerification();
      print("Verification email sent to ${userCredential.user?.email}");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': FirebaseAuth.instance.currentUser?.uid, // ✅ Add this line
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'role': selectedRole,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/animations/gradient7.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: Lottie.asset(
                        'assets/animations/hi.json',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create Your Account',
                      style: TextStyle(
                        color: Colors.white, // Bright text for dark theme
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    MyTextField(
                      controller: usernameController,
                      hintText: 'Username',
                      obscureText: false,
                      backgroundColor: Colors.black45, // Darker input field
                      textColor: Colors.white,
                      borderColor: Colors.grey,
                      borderRadius: 25,
                    ),
                    const SizedBox(height: 15),
                    MyTextField(
                      controller: emailController,
                      hintText: 'Email',
                      obscureText: false,
                      backgroundColor: Colors.black45,
                      textColor: Colors.white,
                      borderColor: Colors.grey,
                      borderRadius: 25,
                    ),
                    const SizedBox(height: 15),
                    MyTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true,
                      backgroundColor: Colors.black45,
                      textColor: Colors.white,
                      borderColor: Colors.grey,
                      borderRadius: 25,
                    ),
                    const SizedBox(height: 15),
                    MyTextField(
                      controller: confirmPasswordController,
                      hintText: 'Confirm Password',
                      obscureText: true,
                      backgroundColor: Colors.black45,
                      textColor: Colors.white,
                      borderColor: Colors.grey,
                      borderRadius: 25,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Student',
                              style: TextStyle(color: Colors.white)),
                          selected: selectedRole == 'student',
                          selectedColor: Colors.blueGrey,
                          backgroundColor: Colors.black45,
                          onSelected: (isSelected) {
                            setState(() {
                              selectedRole = 'student';
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Teacher',
                              style: TextStyle(color: Colors.white)),
                          selected: selectedRole == 'teacher',
                          selectedColor: Colors.blueGrey,
                          backgroundColor: Colors.black45,
                          onSelected: (isSelected) {
                            setState(() {
                              selectedRole = 'teacher';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    MyButton(
                      onTap: () => registerUser(context),
                      text: 'Register',
                      backgroundColor: Colors.blueGrey,
                      textColor: Colors.white,
                      borderRadius: 25,
                      shadowColor: Colors.black.withOpacity(0.1),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Login now',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
