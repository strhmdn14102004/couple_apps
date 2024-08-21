import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
   final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, LatLng> _usersPositions = {};
  Map<String, double> _usersSpeeds = {};
  Map<String, double> _distances = {};
  Map<String, String> _usersNames = {}; // Map to store user full names
  Map<String, BitmapDescriptor> _userIcons =
      {}; // Map to store custom marker icons
  List<Polyline> _polylines = [];
  String? photoProfile;
  Set<Marker> _markers = {};
  String? _selectedUserId;
  MapType _currentMapType = MapType.satellite;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenToUsersLocations();
  }
Future<void> showDeviceInfo(BuildContext context) async {
    try {
      // Get current user ID
      User? user = _auth.currentUser;
      String userId = user!.uid;

      // Fetch device info from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      var data = userDoc.data() as Map<String, dynamic>?;

      // Show modal bottom sheet with device info
      if (data != null) {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Battery: ${data['battery']}%"),
                  Text("Network: ${data['network']}"),
                  Text("Device Model: ${data['deviceModel']}"),
                ],
              ),
            );
          },
        );
      } else {
        print("No device data found for user.");
      }
    } catch (e) {
      print("Error fetching device info: $e");
    }
  }
  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.satellite
          ? MapType.normal
          : MapType.satellite;
    });
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    photoProfile = userDoc.data()?['photoProfile'] as String? ??
        'https://your-default-photo-url.com/photo.jpg';

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'location': GeoPoint(position.latitude, position.longitude),
      'speed': position.speed,
    }, SetOptions(merge: true));

    _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
  }

  Future<BitmapDescriptor> _createMarkerImageFromUrl(String url) async {
    final Completer<BitmapDescriptor> completer = Completer();
    final ImageConfiguration imageConfiguration =
        createLocalImageConfiguration(context);

    NetworkImage(url)
      ..resolve(imageConfiguration).addListener(
        ImageStreamListener((ImageInfo imageInfo, bool _) async {
          final ui.Image image = imageInfo.image;

          final resizedImage = await _resizeAndCropImageToCircle(image, 100);

          final ByteData? resizedByteData =
              await resizedImage.toByteData(format: ui.ImageByteFormat.png);
          final Uint8List resizedImageData =
              resizedByteData!.buffer.asUint8List();

          final BitmapDescriptor bitmap =
              BitmapDescriptor.fromBytes(resizedImageData);
          completer.complete(bitmap);
        }),
      );

    return completer.future;
  }

  Future<ui.Image> _resizeAndCropImageToCircle(ui.Image image, int size) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint();

    // Create a circular clip path
    final Path clipPath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size / 2, size / 2), radius: size / 2));
    canvas.clipPath(clipPath);

    // Draw the image within the circular clip path
    final Rect srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final Rect dstRect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());

    canvas.drawImageRect(image, srcRect, dstRect, paint);

    final ui.Picture picture = recorder.endRecording();
    final ui.Image circularImage = await picture.toImage(size, size);

    return circularImage;
  }

  Future<ui.Image> _resizeImage(ui.Image image, int width, int height) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    final Size size = Size(width.toDouble(), height.toDouble());
    final Paint paint = Paint();

    final Rect src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final Rect dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, src, dst, paint);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image resizedImage = await picture.toImage(width, height);
    return resizedImage;
  }

  Future<BitmapDescriptor> _getMarkerIcon(String? imageUrl) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context);
      BitmapDescriptor bitmap = await BitmapDescriptor.fromAssetImage(
        imageConfiguration,
        imageUrl,
      );
      return bitmap;
    } else {
      return BitmapDescriptor.defaultMarker;
    }
  }

  void _addMarkers() async {
    Set<Marker> markers = {};

    // Create and add the marker for your own location
    if (_currentPosition != null) {
      BitmapDescriptor userIcon;

      // Check if the photoProfile is valid
      if (photoProfile != null && photoProfile!.isNotEmpty) {
        userIcon = await _createMarkerImageFromUrl(photoProfile!);
      } else {
        // Fallback to a default marker if no photoProfile is provided
        userIcon = BitmapDescriptor.defaultMarker;
      }

      markers.add(
        Marker(
          markerId: MarkerId(userId),
          position: _currentPosition!,
          infoWindow: const InfoWindow(
            title: 'Your Location',
          ),
          icon: userIcon, // Use the custom icon for your location
        ),
      );
    }

    // Create and add markers for other users
    for (var id in _usersPositions.keys) {
      BitmapDescriptor userIcon;

      if (_userIcons[id] != null) {
        userIcon = _userIcons[id]!;
      } else {
        userIcon = BitmapDescriptor.defaultMarker;
      }

      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: _usersPositions[id]!,
          infoWindow: InfoWindow(
            title: _usersNames[id],
            snippet: 'Speed: ${_usersSpeeds[id]?.toStringAsFixed(2)} m/s\n'
                'Distance: ${_distances[id]?.toStringAsFixed(2)} km',
          ),
          icon: userIcon, // Use the custom icon for other users
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _listenToUsersLocations() {
    FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      Map<String, LatLng> usersPositions = {};
      Map<String, double> usersSpeeds = {};
      Map<String, double> distances = {};
      Map<String, String> usersNames = {}; // Temp map for names
      List<Polyline> polylines = [];
      Map<String, BitmapDescriptor> userIcons = {}; // Temp map for custom icons

      for (var doc in snapshot.docs) {
        final location = doc.data()['location'] as GeoPoint?;
        final speed = doc.data()['speed'] as double?;
        final distance = doc.data()['distance'] as double?;
        final fullName = doc.data()['fullName'] as String?; // Get full name
        final photoUrl = doc.data()['photoProfile'] as String?; // Get photo URL

        if (location != null && doc.id != userId) {
          LatLng userLatLng = LatLng(location.latitude, location.longitude);
          usersPositions[doc.id] = userLatLng;
          usersSpeeds[doc.id] = speed ?? 0.0;
          usersNames[doc.id] = fullName ?? 'Unknown User'; // Store full name

          if (photoUrl != null) {
            _createMarkerImageFromUrl(photoUrl).then((bitmap) {
              setState(() {
                _userIcons[doc.id] = bitmap;
              });
            });
          }

          if (_currentPosition != null) {
            double distanceInMeters = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              userLatLng.latitude,
              userLatLng.longitude,
            );
            distances[doc.id] = distanceInMeters / 1000;
            _updateUserDistance(doc.id, distances[doc.id]!);

            polylines.add(
              Polyline(
                polylineId: PolylineId(doc.id),
                visible: true,
                points: [_currentPosition!, userLatLng],
                color: Colors.blue,
                width: 5,
              ),
            );
          }
        }
      }

      setState(() {
        _usersPositions = usersPositions;
        _usersSpeeds = usersSpeeds;
        _distances = distances;
        _usersNames = usersNames; // Update the state with names
        _userIcons = userIcons; // Update the state with custom icons
        _polylines = polylines;
      });
    });
  }

  void _updateUserDistance(String userId, double distance) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'distance': distance,
    });
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {};

    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: MarkerId(userId),
          position: _currentPosition!,
          infoWindow: const InfoWindow(
            title: 'Your Location',
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    }

    _usersPositions.forEach((id, position) {
      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: position,
          infoWindow: InfoWindow(
            title: _usersNames[id], // Use full name as the title
            snippet: 'Speed: ${_usersSpeeds[id]?.toStringAsFixed(2)} m/s\n'
                'Distance: ${_distances[id]?.toStringAsFixed(2)} km',
          ),
          icon: _userIcons[id] ??
              BitmapDescriptor.defaultMarker, // Use custom icon or default
        ),
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType, // Use the current map type
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? const LatLng(0, 0),
              zoom: 14.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(_currentPosition!),
                );
              }
            },
            markers: markers,
            polylines: Set<Polyline>.of(_polylines),
          ),
          Positioned(
            top: 40,
            left: 30,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profilePage');
              },
              child: CircleAvatar(
                backgroundImage:
                    photoProfile != null && photoProfile!.isNotEmpty
                        ? NetworkImage(photoProfile!)
                        : const AssetImage('assets/images/default_profile.png')
                            as ImageProvider,
                radius: 30,
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 25,
            child: Column(
              children: _distances.entries.map((entry) {
                return Text(
                  '${entry.value.toStringAsFixed(2)} km',
                  style: TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),
          ),
          Positioned(
            right: 20,
            top: 80,
            child: FloatingActionButton(
              onPressed: _toggleMapType,
              child: Icon(
                Icons.location_pin,
                color: Colors.white,
                size: 25,
              ),
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
