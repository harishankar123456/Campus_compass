import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Group Alert System',
      theme: ThemeData.dark(),
      home: GroupPage(),
    );
  }
}

class GroupPage extends StatefulWidget {
  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Define _auth
  List<String> students = ['Student 1', 'Student 2', 'Student 3', 'Student 4'];
  List<String> alerts = [];
  TextEditingController alertController = TextEditingController();
  File? _image;
  String displayName = 'Teacher';

  @override
  void initState() {
    super.initState();
    _fetchDisplayName();
  }

  void _fetchDisplayName() {
    setState(() {
      displayName = _auth.currentUser?.displayName ?? 'Teacher';
    });
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

  void removeStudent(int index) {
    setState(() {
      students.removeAt(index);
    });
  }

  void showAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.black87,
          title: Text('Send Alert', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: alertController,
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
              onPressed: () {
                setState(() {
                  alerts.add(alertController.text);
                  alertController.clear();
                });
                Navigator.pop(context);
              },
              child: Text('Send', style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }

  void showMessages() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.black87,
          title: Text('Previous Alerts', style: TextStyle(color: Colors.white)),
          content: Container(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: alerts
                  .map((alert) => ListTile(
                      title:
                          Text(alert, style: TextStyle(color: Colors.white))))
                  .toList(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Perfect black background
      body: Column(
        children: [
          // Teacher Profile Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black38, blurRadius: 10, spreadRadius: 3)
              ],
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
                Text(displayName,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('Group Name',
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),

          // Group Members Section (With Gradient Background)
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                      image: AssetImage("assets/animations/gradient6.jpg"),
                      fit: BoxFit.cover),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black54, blurRadius: 10, spreadRadius: 3)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Group Members',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white10,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(students[index],
                                  style: TextStyle(color: Colors.white)),
                              trailing: IconButton(
                                icon: Icon(Icons.remove_circle,
                                    color: Colors.redAccent),
                                onPressed: () => removeStudent(index),
                              ),
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

      // Floating Glassmorphic Bottom Navigation Bar
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 3)
          ],
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
                    onPressed: showAlertDialog,
                    icon: Icon(Icons.chat_bubble, color: Colors.white),
                    label: Text("Alert", style: TextStyle(color: Colors.white)),
                  ),
                  TextButton.icon(
                    onPressed: showMessages,
                    icon: Icon(Icons.message, color: Colors.white),
                    label:
                        Text("Messages", style: TextStyle(color: Colors.white)),
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
