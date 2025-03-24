import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String backgroundTaskKey = "track_location";

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundTaskKey) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print("Background Location: ${position.latitude}, ${position.longitude}");

      // Upload location to Firebase (ensure minimum writes!)
      FirebaseFirestore.instance
          .collection('user_locations')
          .doc("user_id")
          .set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return Future.value(true);
    }
    return Future.value(false);
  });
}

Future<void> startBackgroundTracking() async {
  await Workmanager().registerPeriodicTask(
    "1", // Unique task ID
    backgroundTaskKey,
    frequency: Duration(minutes: 15), // Runs every 15 minutes (adjustable)
  );
}

void stopBackgroundTracking() {
  Workmanager().cancelByUniqueName("1");
}
