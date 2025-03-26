import 'package:flutter/material.dart';

import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:uuid/uuid.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({Key? key}) : super(key: key);

  @override
  _TeacherHomePageState createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  final List<Map<String, String>> groups = [];
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Add these controllers
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescController = TextEditingController();

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dominant white background
      body: Column(
        children: [
          // Profile Section
          Stack(
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/animations/gradient2.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.asset(
                        'assets/animations/profile.jpg',
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _auth.currentUser?.displayName ?? 'Teacher',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Accent dark gray
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.grey,
                    size: 25,
                  ),
                  onPressed: () async {
                    await _auth.signOut();
                    if (mounted) {
                      Navigator.of(context)
                          .pushReplacementNamed('/student_teacher');
                    }
                  },
                ),
              ),
            ],
          ),

          // Guide Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guide:',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Accent color
                  ),
                ),
                const SizedBox(height: 16),
                _buildHelpCard(
                  'Create and Manage Groups',
                  'Teachers can create groups and share the join link with students.',
                ),
              ],
            ),
          ),

          // Group Section
          Expanded(child: _buildGroupsSection()),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.black, // White
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color:
                  const Color(0xFF171616).withOpacity(0.3), // Light gray shadow
              offset: const Offset(0, 20),
              blurRadius: 20,
            ),
          ],
        ),
        child: GNav(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          backgroundColor: Colors.black, // White
          color: Colors.white, // Dark gray icons
          activeColor: Colors.black,
          tabBackgroundColor: Colors.grey, // Warm gray for selected tab
          gap: 8,
          tabs: [
            GButton(
              icon: Icons.add,
              text: "Add Group",
              onPressed: _showAddGroupDialog,
            ),
            GButton(
              icon: Icons.link,
              text: "Generate Link",
              onPressed: _generateGroupLink,
            ),
          ],
        ),
      ),
    );
  }

  // Help Card Widget
  Widget _buildHelpCard(String title, String description) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white10, // White
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Lottie.asset(
                'assets/animations/app_guide.json',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('groups')
          .where('teacherId', isEqualTo: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data?.docs ?? [];
        return _buildGroupList('Your Groups', groups.isEmpty);
      },
    );
  }

  Widget _buildGroupList(String title, bool isEmpty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.black, // White background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (isEmpty)
            const Center(
              child: Text(
                'No Groups Available',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          if (!isEmpty)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('groups')
                    .where('teacherId', isEqualTo: _auth.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final group = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;
                      return _buildGroupCard({
                        'name': group['name'] ?? '',
                        'description': group['description'] ?? '',
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, String> group) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/home');
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white12, // White card
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.group, size: 40, color: Color(0xFFFFFFFF)),
              const SizedBox(height: 10),
              Text(
                group['name']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                group['description']!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _groupDescController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter group description',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _createGroup();
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final groupId = const Uuid().v4();
      await _firestore.collection('groups').doc(groupId).set({
        'name': _groupNameController.text.trim(),
        'description': _groupDescController.text.trim(),
        'teacherId': user.uid,
        'teacherName': user.displayName ?? 'Unknown', // Store username
        'teacherEmail': user.email ?? 'Unknown', // Store email
        'createdAt': FieldValue.serverTimestamp(),
        'groupId': groupId,
      });

      _groupNameController.clear();
      _groupDescController.clear();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    }
  }

  void _generateGroupLink() async {
    try {
      final groups = await _firestore
          .collection('groups')
          .where('teacherId', isEqualTo: _auth.currentUser?.uid)
          .get();

      if (groups.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create a group first!')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Group'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: groups.docs.length,
              itemBuilder: (context, index) {
                final group = groups.docs[index].data();
                return ListTile(
                  title: Text(group['name'] ?? ''),
                  onTap: () {
                    Navigator.pop(context);
                    _showGroupLink(group['groupId']);
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showGroupLink(String groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with your students:'),
            const SizedBox(height: 10),
            SelectableText(
              groupId,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
