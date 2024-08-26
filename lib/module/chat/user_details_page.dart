import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailsPage extends StatelessWidget {
  final String userId;

  UserDetailsPage({required this.userId});

  Future<DocumentSnapshot> _getUserData() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loading...'),
              centerTitle: true,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              centerTitle: true,
            ),
            body: const Center(child: Text('Error fetching user data')),
          );
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('User not found'),
              centerTitle: true,
            ),
            body: const Center(child: Text('User not found')),
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String userName = userData['fullName'] ?? 'User';

        // Handling GeoPoint for location
        GeoPoint location = userData['location'];
        String locationString =
            'Lat: ${location.latitude}, Lng: ${location.longitude}';

        return Scaffold(
          appBar: AppBar(
            title: Text('Tentang $userName'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      backgroundImage:
                          NetworkImage(userData['photoProfile'] ?? ''),
                      radius: 100,
                      backgroundColor:
                          Colors.grey.shade300, // Placeholder color
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Divider(color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  _buildDetailRow('Perangkat:', userData['deviceModel']),
                  _buildDetailRow('Level Batterai:', '${userData['battery']}%'),
                  _buildDetailRow('Lokasi:', locationString),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
