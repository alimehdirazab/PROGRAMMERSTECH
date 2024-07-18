import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoogleMapController? mapController;
  Position? currentPosition;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      print('Location permission denied');
    }
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      currentPosition = position;
      _addMarker(position.latitude, position.longitude, "Current Location");
      _findNearbyRestaurants(position);
    });
  }

  void _addMarker(double lat, double lng, String title) {
    final marker = Marker(
      markerId: MarkerId(title),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(title: title),
    );
    setState(() {
      markers.add(marker);
    });
  }

  Future<void> _findNearbyRestaurants(Position position) async {
    const apiKey = 'AIzaSyDFQrBOghjpITN6mI7kmTJKqmIW7nc5YvQ';
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${position.latitude},${position.longitude}&radius=1500&type=restaurant&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Response: ${data.toString()}"); // Log the entire response
      final results = data['results'];
      for (var result in results) {
        final location = result['geometry']['location'];
        _addMarker(
          location['lat'],
          location['lng'],
          result['name'],
        );
      }
    } else {
      throw Exception('Failed to load nearby restaurants');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Near Restaurant Finder'),
        ),
        body: currentPosition == null
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                      currentPosition!.latitude, currentPosition!.longitude),
                  zoom: 14,
                ),
                markers: markers,
              ),
      ),
    );
  }
}
