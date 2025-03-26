import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController =
      TextEditingController(text: "+1234567890");
  TextEditingController roleController = TextEditingController(text: "Teacher");
  TextEditingController schoolController =
      TextEditingController(text: "XYZ School");
  bool isEditing = false;
  File? _image;
  String userId = ""; // Store user ID

  @override
  void initState() {
    super.initState();
    _fetchUserDetails(); // Fetch user details when page loads
    _fetchUserName(); // Fetch user name from authentication
  }

  /// 🔥 Fetches user details from Firestore based on current logged-in user's email
  Future<void> _fetchUserDetails() async {
    try {
      User? user =
          FirebaseAuth.instance.currentUser; // Get currently logged-in user
      if (user != null) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email) // Query by email
            .limit(1) // Ensure only one document is retrieved
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userDoc =
              userQuery.docs.first; // Get the first matching document
          setState(() {
            nameController.text =
                userDoc['username'] ?? "User"; // Fetch username
            emailController.text =
                userDoc['email'] ?? "user@example.com"; // Fetch email
            phoneController.text =
                userDoc['phone'] ?? "+1234567890"; // Fetch phone
            schoolController.text =
                userDoc['college'] ?? "XYZ School"; // Fetch college/school
            roleController.text = userDoc['role'] ?? "Teacher"; // Fetch role
          });
        } else {
          print('User document does not exist');
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  /// 🔥 Fetches user name from Firebase Authentication
  void _fetchUserName() {
    User? user =
        FirebaseAuth.instance.currentUser; // Get currently logged-in user
    if (user != null) {
      setState(() {
        nameController.text = user.displayName ?? "User"; // Fetch display name
      });
    }
  }

  /// 🔥 Updates user details in Firestore
  Future<void> _updateUserDetails() async {
    try {
      User? user =
          FirebaseAuth.instance.currentUser; // Get currently logged-in user
      if (user != null) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email) // Ensure correct document
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userDoc = userQuery.docs.first;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id) // Use document ID to update
              .update({
            'phone': phoneController.text.trim(),
            'college': schoolController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(), // Force update
          });

          print("User details updated successfully.");
        }
      }
    } catch (e) {
      print("Error updating user details: $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black, // Entire screen perfect black
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              // Profile Section with Black Shade Overlay
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      Colors.black.withOpacity(0.7), // Black shade for blending
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 10,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white,
                        backgroundImage: _image != null
                            ? FileImage(_image!) // User-selected image
                            : AssetImage("assets/animations/profile2.jpg")
                                as ImageProvider, // Default profile picture
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      nameController.text, // Display name from authentication
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),

              // User Information Section with Gradient Background
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: AssetImage(
                            "assets/animations/gradient1.jpg"), // Apply gradient image
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          buildTextField("Phone Number", phoneController,
                              isEditing, Icons.phone),
                          buildTextField("Role", roleController, false,
                              Icons.school), // Role is not editable
                          buildTextField("College/School", schoolController,
                              isEditing, Icons.business),
                          buildTextField("Email", emailController, false,
                              Icons.email), // Email is not editable
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isEditing = !isEditing;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white24,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 35, vertical: 14),
                                ),
                                child: Text(isEditing ? "Cancel" : "Edit",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white)),
                              ),
                              if (isEditing)
                                ElevatedButton(
                                  onPressed: () async {
                                    await _updateUserDetails(); // Update Firestore
                                    setState(() {
                                      isEditing = false; // Exit edit mode
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 35, vertical: 14),
                                  ),
                                  child: Text("Save",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white)),
                                ),
                            ],
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
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      bool isEnabled, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        enabled: isEnabled,
        style: TextStyle(fontSize: 18, color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          labelText: label,
          labelStyle: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white54),
          ),
          filled: true,
          fillColor: Colors.white10,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
