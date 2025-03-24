import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:projects/pages/profile_page.dart';
import 'package:permission_handler/permission_handler.dart';
import '../backend.dart'; // Import the backend file
import '../pages/teacher_group_page.dart'; // Import Teacher Group Page
import '../pages/student_group_page.dart';
import '../background_service.dart'; // Import background service

class IVTrackingHome extends StatefulWidget {
  @override
  _IVTrackingHomeState createState() => _IVTrackingHomeState();
}

class _IVTrackingHomeState extends State<IVTrackingHome> {
  String? userRole;
  bool isSliderVisible = false;
  GoogleMapController? mapController;

  // Variables for geofence creation
  double geofenceRadius = 100.0; // in meters
  LatLng? selectedLocation;
  Set<Circle> geofenceCircles = {};

  // Define the initial position of the camera
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    requestLocationPermission(); // Request location permission
    startBackgroundTracking(); // This should now work!
    _fetchUserRole(); // Fetch user role from backend
    _loadGeofencesForGroup("groupId123"); // Load geofences for the group
  }

  void _fetchUserRole() async {
    userRole = await Backend.fetchUserRole(); // Call backend function
    setState(() {});
  }

  void _loadGeofencesForGroup(String groupId) async {
    final geofences = await Backend.fetchGeofencesForGroup(groupId);
    setState(() {
      if (geofences.isNotEmpty) {
        final latestGeofence = geofences.last;
        final center = LatLng(
          latestGeofence['center']['lat'],
          latestGeofence['center']['lng'],
        );
        geofenceCircles = {
          Circle(
            circleId: CircleId(center.toString()),
            center: center,
            radius: latestGeofence['radius'],
            fillColor: Colors.blue.withOpacity(0.5),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
        };
      } else {
        geofenceCircles.clear();
      }
    });
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.locationAlways.request();
    if (status.isGranted) {
      print("Location Permission Granted");
    } else if (status.isDenied) {
      print("Location Permission Denied");
    } else if (status.isPermanentlyDenied) {
      openAppSettings(); // Opens settings if permanently denied
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer(); // Open the drawer
                },
              ),
            ),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.map, color: Colors.blue),
                  title: Text('Map'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.group, color: Colors.blue),
                  title: Text('Groups'),
                  onTap: () {
                    if (userRole == 'teacher') {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => GroupPage()));
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => StudentPage()));
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person, color: Colors.blue),
                  title: Text('Profile'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(),
                      ),
                    );
                  },
                ),
                if (userRole ==
                    'teacher') // Add "Create Geofence" option for teachers
                  ListTile(
                    leading: Icon(Icons.add_location_alt, color: Colors.blue),
                    title: Text('Create Geofence'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Future.delayed(Duration(milliseconds: 300), () {
                        _showGeofenceBottomSheet(
                            context); // Correctly invoke the function
                      });
                    },
                  ),
              ],
            ),
          ),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: initialCameraPosition,
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                mapType: MapType.normal,
                compassEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                circles: geofenceCircles, // Display geofences
              ),
              // Bottom Navigation Bar
              //removed bottom navigation bar
              // Removed Teacher-specific Edit Button
            ],
          ),
        );
      },
    );
  }

  void _showGeofenceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: initialCameraPosition,
                      onMapCreated: (GoogleMapController controller) {
                        mapController = controller;
                      },
                      onTap: (LatLng tappedPoint) {
                        setState(() {
                          selectedLocation = tappedPoint;
                          geofenceCircles = {
                            Circle(
                              circleId: CircleId(tappedPoint.toString()),
                              center: tappedPoint,
                              radius: geofenceRadius,
                              fillColor: Colors.blue.withOpacity(0.5),
                              strokeColor: Colors.blue,
                              strokeWidth: 2,
                            ),
                          };
                        });
                      },
                      circles: geofenceCircles,
                      myLocationEnabled: true,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Adjust Geofence Radius'),
                        Slider(
                          value: geofenceRadius,
                          min: 50,
                          max: 500,
                          divisions: 9,
                          label: '${geofenceRadius.round()} meters',
                          onChanged: (value) {
                            setState(() {
                              geofenceRadius = value;
                              if (selectedLocation != null) {
                                geofenceCircles = {
                                  Circle(
                                    circleId:
                                        CircleId(selectedLocation.toString()),
                                    center: selectedLocation!,
                                    radius: geofenceRadius,
                                    fillColor: Colors.blue.withOpacity(0.5),
                                    strokeColor: Colors.blue,
                                    strokeWidth: 2,
                                  ),
                                };
                              }
                            });
                          },
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (selectedLocation != null) {
                              // Delete old geofence data before saving the new one
                              await Backend.deleteOldGeofenceFromFirebase(
                                  "groupId123"); // Replace with actual group ID
                              await Backend.saveGeofenceToFirebase(
                                  selectedLocation!,
                                  geofenceRadius,
                                  "groupId123"); // Replace with actual group ID
                              _loadGeofencesForGroup(
                                  "groupId123"); // Reload geofences after saving
                              Navigator.pop(context);
                            }
                          },
                          child: Text('Confirm Geofence'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}
