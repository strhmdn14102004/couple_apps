import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_app/module/profile/profile_page.dart';
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
  Map<String, String> _usersNames = {};
  Map<String, BitmapDescriptor> _userIcons = {};
  List<Polyline> _polylines = [];
  String? photoProfile;
  Set<Marker> _markers = {};
  String? _selectedUserId;
  String? _currentRoomCode;
  MapType _currentMapType = MapType.satellite;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenToUsersLocations();
    _fetchUserRoomCode();
  }

  Future<void> _fetchUserRoomCode() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final roomCode = userDoc.data()?['roomCode'] as String?;

    setState(() {
      _currentRoomCode = roomCode; // Store the room code
    });

    if (_currentRoomCode != null) {
      _listenToUsersLocations(); // Listen to locations once room code is available
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

    // Add the user's marker after getting the location
    _addUserMarker();
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
    final Path clipPath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size / 2, size / 2), radius: size / 2));
    canvas.clipPath(clipPath);
    final Rect srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final Rect dstRect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    canvas.drawImageRect(image, srcRect, dstRect, paint);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image circularImage = await picture.toImage(size, size);
    return circularImage;
  }

  void _addUserMarker() async {
    if (_currentPosition != null) {
      BitmapDescriptor userIcon;
      if (photoProfile != null && photoProfile!.isNotEmpty) {
        userIcon = await _createMarkerImageFromUrl(photoProfile!);
      } else {
        userIcon = BitmapDescriptor.defaultMarker;
      }

      // Fetch user details from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data();

      // Get additional info like battery, network, etc.
      final battery = userData?['battery'] ?? 'Unknown';
      final network = userData?['network'] ?? 'Unknown';
      final deviceModel = userData?['deviceModel'] ?? 'Unknown';

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(userId),
            position: _currentPosition!,
            icon: userIcon,
            infoWindow: InfoWindow(
              title: userData?['fullName'] ?? 'Your Location',
              snippet:
                  'Device: $deviceModel\nBattery: $battery%\nNetwork: $network',
            ),
            onTap: () {
              _selectedUserId = userId;
              showDeviceInfo(context, userId, userData?['emoji'] ?? '');
            },
          ),
        );
      });
    }
  }

  void _addMarkers(Map<String, String> userEmojis) {
    // Add your marker logic here, making use of userEmojis as needed.
    for (var userId in _usersPositions.keys) {
      final position = _usersPositions[userId];
      final icon = _userIcons[userId];
      final emoji = userEmojis[userId]; // Access the emoji for this user

      if (position != null && icon != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(userId),
            position: position,
            icon: icon,
            infoWindow: InfoWindow(
              title: _usersNames[userId],
              snippet:
                  'Speed: ${_usersSpeeds[userId]?.toStringAsFixed(1)} km/h, Distance: ${_distances[userId]?.toStringAsFixed(1)} Km',
            ),
            onTap: () {
              _selectedUserId = userId; // Corrected from 'id' to 'userId'
              showDeviceInfo(context, userId,
                  emoji.toString()); // Show device info when a marker is tapped
            },
          ),
        );
      }
    }

    // Call setState to update the markers on the map
    setState(() {
      _markers = _markers;
    });
  }

  void _listenToUsersLocations() {
    if (_currentRoomCode == null) return; // Ensure roomCode is available

    FirebaseFirestore.instance
        .collection('users')
        .where('roomCode', isEqualTo: _currentRoomCode) // Filter by roomCode
        .snapshots()
        .listen((snapshot) {
      Map<String, LatLng> usersPositions = {};
      Map<String, double> usersSpeeds = {};
      Map<String, double> distances = {};
      Map<String, String> usersNames = {};
      Map<String, String> userEmojis = {}; // New map for emojis
      Map<String, BitmapDescriptor> userIcons = {};
      List<Polyline> polylines = [];

      for (var doc in snapshot.docs) {
        final location = doc.data()['location'] as GeoPoint?;
        final speed = (doc.data()['speed'] as num?)?.toDouble();
        final distance = (doc.data()['distance'] as num?)?.toDouble();
        final fullName = doc.data()['fullName'] as String?;
        final photoUrl = doc.data()['photoProfile'] as String?;
        final emoji = doc.data()['emoji'] as String?; // Fetch the emoji

        if (location != null && doc.id != userId) {
          usersPositions[doc.id] =
              LatLng(location.latitude, location.longitude);
          usersSpeeds[doc.id] = speed ?? 0;
          distances[doc.id] = distance ?? 0;
          usersNames[doc.id] = fullName ?? 'Unknown User';
          userEmojis[doc.id] = emoji ?? ''; // Store the emoji

          // Load user photo profile if available
          if (photoUrl != null && photoUrl.isNotEmpty) {
            _createMarkerImageFromUrl(photoUrl).then((icon) {
              userIcons[doc.id] = icon;
              _userIcons[doc.id] = icon;
              _addMarkers(userEmojis); // Update here
            });
          }

          if (_currentPosition != null &&
              usersPositions[doc.id] != null &&
              doc.id != userId) {
            final polyline = Polyline(
              polylineId: PolylineId(doc.id),
              points: [_currentPosition!, usersPositions[doc.id]!],
              color: Colors.blue,
              width: 3,
            );
            polylines.add(polyline);
          }
        }

        setState(() {
          _usersPositions = usersPositions;
          _usersSpeeds = usersSpeeds;
          _distances = distances;
          _usersNames = usersNames;
          _polylines = polylines;
          _userIcons = userIcons;
        });

// Call _addMarkers with userEmojis after setting state
        _addMarkers(userEmojis);
      }
    });
  }

  Future<void> showDeviceInfo(
      BuildContext context, String userId, String emoji) async {
    try {
      // Fetch device info from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      var data = userDoc.data() as Map<String, dynamic>?;

      // Show modal bottom sheet with device info and emoji selection
      if (data != null) {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${data['fullName']}"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.battery_full_rounded),
                    Text("${data['battery']}%"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.network_cell),
                    Text("${data['network']}"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.devices_other_rounded),
                    Text("${data['deviceModel']}"),
                  ],
                ),
                Text('Emoji Buat Kamu: $emoji'),
                const SizedBox(height: 20),
                const Text("Send an emoji:"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _emojiButton(context, userId, '😊'),
                    _emojiButton(context, userId, '😂'),
                    _emojiButton(context, userId, '❤️'),
                    _emojiButton(context, userId, '👍'),
                    _emojiButton(context, userId, '👎'),
                  ],
                ),
              ],
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

  Future<void> _navigateToProfilePage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          onBack: _getCurrentLocation, // Refresh the location
        ),
      ),
    );
  }

  Widget _emojiButton(BuildContext context, String userId, String emoji) {
    return GestureDetector(
      onTap: () {
        print("Emoji $emoji dipilih");
        _sendEmoji(userId, emoji);
        Navigator.pop(context); // Close the modal after sending the emoji
      },
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 30),
      ),
    );
  }

  Future<void> _sendEmoji(String userId, String emoji) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
          {
            'emoji': emoji, // Add the emoji to the user's document
          },
          SetOptions(
              merge:
                  true)); // Use merge to update existing fields without overriding

      print("Emoji sent to $userId: $emoji");
    } catch (e) {
      print("Error sending emoji: $e");
    }
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

    return WillPopScope(
      onWillPop: () async {
        _getCurrentLocation(); // Refresh the location or other relevant data
        return true; // Allow the back navigation
      },
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              mapType: _currentMapType,
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? const LatLng(0, 0),
                zoom: 15.0,
              ),
              markers: _markers,
              polylines: _polylines.toSet(),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentPosition != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(_currentPosition!),
                  );
                }
              },
            ),
            Positioned(
              top: 40,
              left: 30,
              child: GestureDetector(
                onTap: _navigateToProfilePage,
                child: CircleAvatar(
                  backgroundImage: photoProfile != null &&
                          photoProfile!.isNotEmpty
                      ? NetworkImage(photoProfile!)
                      : const AssetImage('assets/images/default_profile.png')
                          as ImageProvider,
                  radius: 30,
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 70,
              child: FloatingActionButton(
                onPressed: _toggleMapType,
                child: const Icon(
                  Icons.layers,
                  color: Colors.black,
                  size: 25,
                ),
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
