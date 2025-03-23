import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:food_app/color.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // For Socket connection

import 'home_page.dart';

class WelcomePage extends StatelessWidget {
  final Map<String, dynamic> connectionDetails; // Add connection details

  const WelcomePage({super.key, required this.connectionDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onLongPress: () {
                _showPinDialog(context);
              },
              child: CarouselImage(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                      connectionDetails: connectionDetails, // Pass connection details
                    ),
                  ),
                );
              },
              child: Container(
                height: 100,
                width: double.infinity,
                color: AppColors.airforceBlue.withAlpha((0.7 * 255).round()),
                child: Center(
                  child: Text(
                    'Touch to start',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show PIN input dialog
  void _showPinDialog(BuildContext context) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter PIN'),
          content: TextField(
            controller: pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter 6-digit PIN',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (pinController.text == '666666') {
                  Navigator.pop(context); // Close the PIN dialog
                  _showSettingsDialog(context); // Show settings dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Incorrect PIN')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Show settings dialog
  void _showSettingsDialog(BuildContext context) {
    final ipController = TextEditingController();
    final portController = TextEditingController();
    bool isConnecting = false;
    String connectionStatus = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ipController,
                    decoration: InputDecoration(
                      labelText: 'IP Address',
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: portController,
                    decoration: InputDecoration(
                      labelText: 'Port',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  if (isConnecting)
                    CircularProgressIndicator(),
                  if (connectionStatus.isNotEmpty)
                    Text(
                      connectionStatus,
                      style: TextStyle(
                        color: connectionStatus.contains('success') ? Colors.green : Colors.red,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final ip = ipController.text.trim();
                    final port = int.tryParse(portController.text.trim());

                    if (ip.isEmpty || port == null) {
                      setState(() {
                        connectionStatus = 'Please enter a valid IP address and port.';
                      });
                      return;
                    }

                    setState(() {
                      isConnecting = true;
                      connectionStatus = 'Connecting...';
                    });

                    try {
                      final socket = await Socket.connect(ip, port, timeout: Duration(seconds: 5));
                      await socket.flush();
                      socket.destroy();

                      setState(() {
                        isConnecting = false;
                        connectionStatus = 'Connected successfully!';
                      });

                      // Close the settings dialog after a short delay
                      Future.delayed(Duration(seconds: 1), () {
                        Navigator.pop(context); // Close the settings dialog
                      });
                    } on SocketException catch (e) {
                      setState(() {
                        isConnecting = false;
                        connectionStatus = 'Failed to connect: ${e.message}';
                      });
                    } catch (e) {
                      setState(() {
                        isConnecting = false;
                        connectionStatus = 'Error: $e';
                      });
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class CarouselImage extends StatefulWidget {
  const CarouselImage({super.key});

  @override
  CarouselImageState createState() => CarouselImageState();
}

class CarouselImageState extends State<CarouselImage> {
  List<String> imageUrls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    try {
      final response = await http.get(Uri.parse('https://raw.githubusercontent.com/JayMatawaran/APIs/refs/heads/main/logo.json'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> recipes = data['users'];

        final filteredRecipes =
        recipes.where((recipe) => [2, 4, 7].contains(recipe['id'])).toList();

        setState(() {
          imageUrls = filteredRecipes.map((recipe) => recipe['image'] as String).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load images');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 1.0,
      ),
      items: imageUrls.map((imageUrl) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    );
  }
}