import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_app/color.dart';
import 'package:food_app/pages/login_page.dart';
import 'package:food_app/pages/welcome_page.dart';
import 'package:food_app/services/connection_service.dart';
import 'package:http/http.dart' as http;

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

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _merchantSearchController =
      TextEditingController();
  final TextEditingController _posSearchController = TextEditingController();

  bool _isConnected = false;
  String _connectionStatus = 'Not connected';
  StreamSubscription<bool>? _connectionSubscription;
  final ConnectionService _connectionService = ConnectionService();

  @override
  void initState() {
    super.initState();
    _ipController.text = '192.168.1.14';
    _portController.text = '4040';
    fetchMerchants();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _ipController.dispose();
    _portController.dispose();
    _merchantSearchController.dispose();
    _posSearchController.dispose();
    super.dispose();
  }

  Future<void> fetchMerchants() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Loading merchants...';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
                'https://raw.githubusercontent.com/jayMatawaran/APIs/refs/heads/main/merchants%26pos.json'),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          merchants = data['merchants'] ?? [];
          _connectionStatus = merchants.isEmpty ? 'No merchants available' : '';
        });
      } else {
        throw Exception('Failed to load merchants: ${response.statusCode}');
      }
    } on SocketException {
      setState(() => _connectionStatus = 'No internet connection');
    } on TimeoutException {
      setState(() => _connectionStatus = 'Request timed out');
    } catch (e) {
      setState(() => _connectionStatus = 'Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void onMerchantSelected(String merchant) {
    setState(() {
      selectedMerchant = merchant;
      isMerchantSelected = true;
      selectedPos = null;
      isPosSelected = false;
      posList = merchants.firstWhere(
        (m) => m['merchant_name'] == merchant,
        orElse: () => {'pos_systems': []},
      )['pos_systems'];
    });
  }

  void onPosSelected(String pos) {
    setState(() {
      selectedPos = pos;
      isPosSelected = true;
    });
  }

  Future<void> _connectToServer() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 4040;

    if (ip.isEmpty) {
      setState(() => _connectionStatus = 'Please enter valid IP');
      return;
    }

    setState(() {
      _connectionStatus = 'Connecting...';
    });

    // Cancel any existing subscription
    _connectionSubscription?.cancel();

    // Set up new subscription
    _connectionSubscription =
        _connectionService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _connectionStatus = connected ? 'Connected' : 'Disconnected';
        });
      }
    });

    try {
      await _connectionService.connect(ip, port);
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus = 'Error: ${e.toString()}';
        });
      }
    }
  }

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
              if (_isLoading) const CircularProgressIndicator(),
              if (_connectionStatus.isNotEmpty &&
                  !_isLoading &&
                  merchants.isEmpty)
                Column(
                  children: [
                    Text(_connectionStatus),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: fetchMerchants,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              if (merchants.isNotEmpty) ...[
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (context) => _MerchantSelectionPanel(
                        merchants: merchants,
                        onSelected: onMerchantSelected,
                        searchController: _merchantSearchController,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: AppColors.jet,
                    ),
                    child: Text(
                      selectedMerchant ?? 'Select Merchant',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (isMerchantSelected) ...[
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (context) => _PosSelectionPanel(
                        posList: posList,
                        onSelected: onPosSelected,
                        searchController: _posSearchController,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: AppColors.jet,
                    ),
                    child: Text(
                      selectedPos ?? 'Select POS',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (isPosSelected) ...[
                const Text('Enter Connection Details',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  width: buttonWidth,
                  child: TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'IP Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: buttonWidth,
                  child: TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton(
                    onPressed: _connectionService.isConnecting
                        ? null
                        : _connectToServer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor:
                          _isConnected ? Colors.green : AppColors.jet,
                    ),
                    child: _connectionService.isConnecting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isConnected ? 'Connected' : 'Connect',
                            style: const TextStyle(color: Colors.white),
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
              if (_isConnected) ...[
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WelcomePage(
                            connectionDetails: {
                              'ip': _ipController.text.trim(),
                              'port': _portController.text.trim(),
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: AppColors.airforceBlue,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
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

class _MerchantSelectionPanel extends StatefulWidget {
  final List<dynamic> merchants;
  final Function(String) onSelected;
  final TextEditingController searchController;

  const _MerchantSelectionPanel({
    required this.merchants,
    required this.onSelected,
    required this.searchController,
  });

  @override
  State<_MerchantSelectionPanel> createState() =>
      _MerchantSelectionPanelState();
}

class _MerchantSelectionPanelState extends State<_MerchantSelectionPanel> {
  late List<dynamic> filteredMerchants;

  @override
  void initState() {
    super.initState();
    filteredMerchants = widget.merchants;
    widget.searchController.addListener(_filterMerchants);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_filterMerchants);
    super.dispose();
  }

  void _filterMerchants() {
    final query = widget.searchController.text.toLowerCase();
    setState(() {
      filteredMerchants = widget.merchants.where((merchant) {
        final name = merchant['merchant_name'].toString().toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: widget.searchController,
            decoration: const InputDecoration(
              labelText: 'Search Merchants',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: filteredMerchants.length,
              itemBuilder: (context, index) {
                final merchant =
                    filteredMerchants[index]['merchant_name'].toString();
                return ListTile(
                  title: Text(merchant),
                  onTap: () {
                    widget.onSelected(merchant);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PosSelectionPanel extends StatefulWidget {
  final List<dynamic> posList;
  final Function(String) onSelected;
  final TextEditingController searchController;

  const _PosSelectionPanel({
    required this.posList,
    required this.onSelected,
    required this.searchController,
  });

  @override
  State<_PosSelectionPanel> createState() => _PosSelectionPanelState();
}

class _PosSelectionPanelState extends State<_PosSelectionPanel> {
  late List<dynamic> filteredPosList;

  @override
  void initState() {
    super.initState();
    filteredPosList = widget.posList;
    widget.searchController.addListener(_filterPosList);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_filterPosList);
    super.dispose();
  }

  void _filterPosList() {
    final query = widget.searchController.text.toLowerCase();
    setState(() {
      filteredPosList = widget.posList.where((pos) {
        final name = pos['pos_name'].toString().toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: widget.searchController,
            decoration: const InputDecoration(
              labelText: 'Search POS Systems',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPosList.length,
              itemBuilder: (context, index) {
                final pos = filteredPosList[index]['pos_name'].toString();
                return ListTile(
                  title: Text(pos),
                  onTap: () {
                    widget.onSelected(pos);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
