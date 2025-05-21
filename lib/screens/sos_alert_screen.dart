//screens/sos_alert_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

class Contact {
  String name;
  String phone;

  Contact({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
  factory Contact.fromJson(Map<String, dynamic> json) =>
      Contact(name: json['name'], phone: json['phone']);
}

class SosScreen extends StatefulWidget {
  const SosScreen({Key? key}) : super(key: key);

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final TextEditingController messageController = TextEditingController();
  List<Contact> contacts = [];
  final Telephony telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request all needed permissions
    await [
      Permission.location,
      Permission.sms,
      Permission.notification, // For Android 13+
    ].request();

    // For Geolocator-specific permissions
    await Geolocator.requestPermission();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      final List<dynamic> contactList = jsonDecode(contactsJson);
      setState(() {
        contacts = contactList.map((e) => Contact.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonContacts = jsonEncode(contacts.map((e) => e.toJson()).toList());
    await prefs.setString('contacts', jsonContacts);
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable location services')),
      );
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> sendNotification() async {
    // Check notification permission for Android 13+
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission is required for proper operation')),
        );
      }
    }

    Position? position = await _determinePosition();

    String locationLink = position != null
        ? '\nLocation: https://maps.google.com/?q=${position.latitude},${position.longitude}'
        : '';

    final messageWithLocation = '${messageController.text}$locationLink';

    final bool? smsPermissionsGranted = await telephony.requestPhoneAndSmsPermissions;

    if (smsPermissionsGranted == true) {
      for (var contact in contacts) {
        await telephony.sendSms(
          to: contact.phone,
          message: messageWithLocation,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS messages sent')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS Permission Denied')),
      );
    }
  }

  void _showAddContactDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isNotEmpty && phone.isNotEmpty) {
                setState(() {
                  contacts.add(Contact(name: name, phone: phone));
                });
                _saveContacts();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundImage:
                          AssetImage('assets/images/profile.png'),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Good morning',
                                style:
                                TextStyle(fontSize: 14, color: Colors.grey)),
                            Text('Ukshita',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.notifications_none),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.warning_amber_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'Notify Loved One',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Quickly notify your pre-selected loved ones in case of a medical emergency.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Write a custom message (optional)...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contacts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == contacts.length) {
                      return ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text('Add Contact'),
                        onTap: _showAddContactDialog,
                      );
                    }
                    final contact = contacts[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(contact.name),
                      subtitle: Text(contact.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            contacts.removeAt(index);
                          });
                          _saveContacts();
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: contacts.isEmpty ? null : sendNotification,
                  child: const Text('Send Notification',
                      style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}