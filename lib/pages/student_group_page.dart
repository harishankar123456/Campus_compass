import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import

class StudentPage extends StatefulWidget {
  @override
  StudentPageState createState() => StudentPageState();
}

class StudentPageState extends State<StudentPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Add this line
  List<String> alerts = ['Welcome to the group!'];
  TextEditingController studentMessageController = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> fetchTeacherEmail() async {
    try {
      final userEmail = _auth.currentUser?.email;
      if (userEmail == null) {
        print('User email is null.');
        return null;
      }

      print('Fetching teacher email for student email: $userEmail');

      final querySnapshot = await _firestore
          .collection('group_members')
          .where('email', isEqualTo: userEmail)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No documents found for student email: $userEmail');
        return null;
      }

      print('Document found: ${querySnapshot.docs.first.data()}');

      return querySnapshot.docs.first['createdBy'] as String?;
    } catch (e) {
      print('Error fetching teacher email: $e');
      return null;
    }
  }

  Future<void> sendMessageToTeacher(String message) async {
    try {
      final teacherEmail = await fetchTeacherEmail();
      if (teacherEmail == null) {
        print('Teacher email not found.');
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated.');
        return;
      }

      await _firestore.collection('alerts').add({
        'message': message,
        'email': teacherEmail,
        'username': user.displayName ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Message sent successfully.');
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> fetchAlerts() async {
    try {
      final teacherEmail = await fetchTeacherEmail();
      if (teacherEmail == null) {
        print('Teacher email not found.');
        return;
      }

      final querySnapshot = await _firestore
          .collection('alerts')
          .where('email', isEqualTo: teacherEmail)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        alerts = querySnapshot.docs.map((doc) {
          final data = doc.data();
          final username = data['username'] ?? 'Unknown';
          final message = data['message'] ?? '';
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
          final formattedTimestamp = timestamp != null
              ? '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}'
              : 'Unknown time';
          return '$username|$message|$formattedTimestamp';
        }).toList();
      });

      print('Alerts fetched successfully.');
    } catch (e) {
      print('Error fetching alerts: $e');
    }
  }

  void showMessagesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white24,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Previous Alerts', style: TextStyle(color: Colors.white)),
          content: Container(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: alerts.map((alert) {
                // Directly use the fetched data
                final data = alert.split(
                    '|'); // Assuming data is stored as 'username|message|timestamp'
                final username = data.length > 0 ? data[0] : 'Unknown';
                final message = data.length > 1 ? data[1] : 'Unknown';
                final timestamp = data.length > 2 ? data[2] : 'Unknown time';
                return ListTile(
                  title: Text(message, style: TextStyle(color: Colors.white)),
                  subtitle: Text('$username ($timestamp)',
                      style: TextStyle(color: Colors.white70)),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: Colors.white))),
          ],
        );
      },
    );
  }

  void showStudentMessageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white24,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Send Message to Teacher',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: studentMessageController,
            decoration: InputDecoration(
                hintText: 'Type your message here...',
                hintStyle: TextStyle(color: Colors.white54)),
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.white))),
            TextButton(
              onPressed: () async {
                final message = studentMessageController.text.trim();
                if (message.isNotEmpty) {
                  await sendMessageToTeacher(message);
                  studentMessageController.clear();
                  await fetchAlerts(); // Refresh alerts after sending
                }
                Navigator.pop(context);
              },
              child: Text('Send', style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : AssetImage("assets/animations/profile.jpg")
                            as ImageProvider,
                  ),
                ),
                SizedBox(height: 10),
                Text(_auth.currentUser?.displayName ?? 'Student',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(
                    _auth.currentUser?.email ??
                        'Student Email Not Found', // Display user email
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                      image: AssetImage("assets/animations/gradient1.jpg"),
                      fit: BoxFit.cover),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Group Alerts',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white10,
                            ),
                            child: ListTile(
                              leading: Icon(Icons.notifications,
                                  color: Colors.white),
                              title: Text(alerts[index],
                                  style: TextStyle(color: Colors.white)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(30),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomAppBar(
            color: Colors.black.withOpacity(0.6),
            shape: CircularNotchedRectangle(),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: showStudentMessageDialog,
                    icon: Icon(Icons.message, color: Colors.white),
                    label: Text("Message Teacher",
                        style: TextStyle(color: Colors.white)),
                  ),
                  TextButton.icon(
                    onPressed: showMessagesDialog,
                    icon: Icon(Icons.history, color: Colors.white),
                    label: Text("Alerts History",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
