import 'package:flutter/material.dart';
import 'package:food_app/color.dart';
import 'package:food_app/pages/login_page.dart';
import 'package:food_app/pages/viewcart_page.dart'; // Import ViewCartPage
import 'package:food_app/pages/welcome_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // For Socket connection

class MerchantPage extends StatefulWidget {
  final String accessToken; // Add accessToken as a parameter

  const MerchantPage({super.key, required this.accessToken});

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

  Future<void> fetchMerchants() async {
    final response = await http.get(
      Uri.parse(
          'https://raw.githubusercontent.com/JayMatawaran/APIs/refs/heads/main/merchants%26pos.json'),
    );

    if (response.statusCode == 200) {
      setState(() {
        merchants = json.decode(response.body)['merchants'];
      });
    } else {
      throw Exception('Failed to load merchants');
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
  Future<void> _attemptConnection() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());

    if (ip.isEmpty || port == null) {
      setState(() {
        _connectionStatus = 'Please enter a valid IP address and port.';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    try {
      final socket = await Socket.connect(ip, port, timeout: Duration(seconds: 5));
      await socket.flush();
      socket.destroy();

      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _connectionStatus = 'Connected successfully!';
        connectionDetails['ip'] = ip; // Update IP
        connectionDetails['port'] = port; // Update port
      });
    } on SocketException catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _connectionStatus = 'Failed to connect: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _connectionStatus = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.8;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: Image.asset('assets/images/logo.png'),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return MerchantSelectionPanel(
                          merchants: merchants,
                          onMerchantSelected: onMerchantSelected,
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: AppColors.jet,
                  ),
                  child: Text(
                    'Select Merchant',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: isMerchantSelected
                      ? () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return PosSelectionPanel(
                          posList: posList,
                          onPosSelected: onPosSelected,
                        );
                      },
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: isMerchantSelected ? AppColors.jet : Colors.grey,
                  ),
                  child: Text(
                    'Select POS',
                    style: TextStyle(
                      fontSize: 18,
                      color: isMerchantSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Show IP and Port fields after POS is selected
              if (isPosSelected)
                Column(
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: TextField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          labelText: 'Enter IP Address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {}); // Rebuild to update button state
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: buttonWidth,
                      child: TextField(
                        controller: _portController,
                        decoration: InputDecoration(
                          labelText: 'Enter Port',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {}); // Rebuild to update button state
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    // Connect Button
                    SizedBox(
                      width: buttonWidth,
                      child: ElevatedButton(
                        onPressed: _isConnecting || !_isValidInput()
                            ? null
                            : _attemptConnection,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: _isConnected ? Colors.green : AppColors.jet,
                        ),
                        child: _isConnecting
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                          _isConnected ? 'Connected' : 'Connect',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        color: _isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: _isConnected
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WelcomePage(
                          connectionDetails: connectionDetails, // Pass connection details
                        ),
                      ),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: _isConnected ? AppColors.airforceBlue : Colors.grey,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      color: _isConnected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text('Logout'),
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