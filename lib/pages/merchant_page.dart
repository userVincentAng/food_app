import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_app/color.dart';
import 'package:food_app/pages/login_page.dart';
import 'package:food_app/pages/welcome_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // For Socket connection

class MerchantPage extends StatefulWidget {


  const MerchantPage({super.key});

  @override
  State<MerchantPage> createState() => _MerchantPageState();
}

class _MerchantPageState extends State<MerchantPage> {
  List<dynamic> merchants = [];
  List<dynamic> posList = [];
  String? selectedMerchant;
  String? selectedPos;
  bool isMerchantSelected = false;
  bool isPosSelected = false;
  bool _isLoading = false;

  // Controllers for IP address and port
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  // State for connection
  bool _isConnecting = false;
  bool _isConnected = false;
  String _connectionStatus = '';

  // Store the IP and port
  Map<String, dynamic> connectionDetails = {
    'ip': '192.168.1.14', // Default IP
    'port': 4040, // Default port
  };

  @override
  void initState() {
    super.initState();
    fetchMerchants();
  }

  void _retryFetchMerchants() {
    setState(() {
      merchants = [];
      selectedMerchant = null;
      selectedPos = null;
      isMerchantSelected = false;
      isPosSelected = false;
    });
    fetchMerchants();
  }

  Future<void> fetchMerchants() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Loading merchants...';
    });

    try {
      final response = await http.get(
        Uri.parse('https://raw.githubusercontent.com/jayMatawaran/APIs/refs/heads/main/merchants%26pos.json'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['merchants'] == null || data['merchants'].isEmpty) {
          throw Exception('No merchants available');
        }

        setState(() {
          merchants = data['merchants'];
          _connectionStatus = '';
        });
      } else {
        throw Exception('Failed to load merchants: ${response.statusCode}');
      }
    } on SocketException {
      setState(() {
        _connectionStatus = 'No internet connection';
      });
    } on TimeoutException {
      setState(() {
        _connectionStatus = 'Request timed out';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void onMerchantSelected(String merchant) {
    setState(() {
      selectedMerchant = merchant;
      isMerchantSelected = true;
      selectedPos = null;
      isPosSelected = false;
      posList = merchants.firstWhere((m) => m['merchant_name'] == merchant)['pos_systems'];
    });
  }

  void onPosSelected(String pos) {
    setState(() {
      selectedPos = pos;
      isPosSelected = true;
    });
  }

  // Validate IP address and port
  bool _isValidInput() {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    return ip.isNotEmpty && port.isNotEmpty;
  }

  // Attempt to connect to the IP address and port
  // Update _attemptConnection method
  Future<void> _attemptConnection() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());

    if (ip.isEmpty || port == null) {
      setState(() {
        _connectionStatus = 'Please enter a valid IP address and port';
      });
      return;
    }

    // Validate IP format
    if (!RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(ip)) {
      setState(() {
        _connectionStatus = 'Invalid IP address format';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 10));
      await socket.flush();
      socket.destroy();

      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _connectionStatus = 'Connected successfully!';
        connectionDetails['ip'] = ip;
        connectionDetails['port'] = port;
      });
    } on SocketException catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _connectionStatus = 'Connection failed: ${e.message}';
      });
    } on TimeoutException {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _connectionStatus = 'Connection timed out';
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _connectionStatus = 'Error: ${e.toString()}';
      });
    }
  }

  // Update build method to include empty states
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.8;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Show loading or error status
              if (_isLoading)
                const CircularProgressIndicator(),
              if (_connectionStatus.isNotEmpty && !_isLoading && merchants.isEmpty)
                ElevatedButton(
                  onPressed: _retryFetchMerchants,
                  child: const Text('Retry'),
                ),

              const SizedBox(height: 20),

              // Merchant selection button (only show if merchants are loaded)
              if (merchants.isNotEmpty) ...[
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => MerchantSelectionPanel(
                          merchants: merchants,
                          onMerchantSelected: onMerchantSelected,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: AppColors.jet,
                    ),
                    child: const Text(
                      'Select Merchant',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // POS selection button (only show if merchant is selected)
              if (isMerchantSelected) ...[
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => PosSelectionPanel(
                          posList: posList,
                          onPosSelected: onPosSelected,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: AppColors.jet,
                    ),
                    child: const Text(
                      'Select POS',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Show IP/Port fields only if POS is selected
              if (isPosSelected) ...[
                const Text(
                  'Enter Connection Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: buttonWidth,
                  child: TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'Enter IP Address',
                      hintText: 'e.g. 192.168.1.1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: buttonWidth,
                  child: TextField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: 'Enter Port',
                      hintText: 'e.g. 4040',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),

                // Connect Button
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton(
                    onPressed: _isConnecting || !_isValidInput() ? null : _attemptConnection,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: _isConnected ? Colors.green : AppColors.jet,
                    ),
                    child: _isConnecting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      _isConnected ? 'Connected' : 'Connect',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  _connectionStatus,
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Continue button (only show if connected)
              if (_isConnected) ...[
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WelcomePage(
                            connectionDetails: connectionDetails,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: AppColors.airforceBlue,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Logout button
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MerchantSelectionPanel extends StatefulWidget {
  final List<dynamic> merchants;
  final Function(String) onMerchantSelected;

  const MerchantSelectionPanel({
    super.key,
    required this.merchants,
    required this.onMerchantSelected,
  });

  @override
  State<MerchantSelectionPanel> createState() => _MerchantSelectionPanelState();
}

class _MerchantSelectionPanelState extends State<MerchantSelectionPanel> {
  List<dynamic> filteredMerchants = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredMerchants = widget.merchants;
    searchController.addListener(_filterMerchants);
  }

  void _filterMerchants() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredMerchants = widget.merchants.where((merchant) {
        final merchantName = merchant['merchant_name'].toLowerCase();
        return merchantName.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search merchants...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredMerchants.length,
            itemBuilder: (context, index) {
              final merchant = filteredMerchants[index]['merchant_name'];
              return ListTile(
                title: Text(merchant),
                onTap: () {
                  widget.onMerchantSelected(merchant);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class PosSelectionPanel extends StatefulWidget {
  final List<dynamic> posList;
  final Function(String) onPosSelected;

  const PosSelectionPanel({
    super.key,
    required this.posList,
    required this.onPosSelected,
  });

  @override
  State<PosSelectionPanel> createState() => _PosSelectionPanelState();
}

class _PosSelectionPanelState extends State<PosSelectionPanel> {
  List<dynamic> filteredPosList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredPosList = widget.posList;
    searchController.addListener(_filterPosList);
  }

  void _filterPosList() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredPosList = widget.posList.where((pos) {
        final posName = pos['pos_name'].toLowerCase();
        return posName.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search POS...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredPosList.length,
            itemBuilder: (context, index) {
              final pos = filteredPosList[index]['pos_name'];
              return ListTile(
                title: Text(pos),
                onTap: () {
                  widget.onPosSelected(pos);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}