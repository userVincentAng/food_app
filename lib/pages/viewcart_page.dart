import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:food_app/color.dart';
import 'package:food_app/models/ordering_device_request.dart';
import 'package:food_app/pages/home_page.dart';
import 'package:food_app/pages/customize_order.dart';
import 'package:food_app/services/connection_service.dart';
import 'package:food_app/widgets/cart_item.dart';
import 'package:uuid/uuid.dart';

class ViewCartPage extends StatefulWidget {
  final Map<String, dynamic> connectionDetails;
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const ViewCartPage({
    super.key,
    required this.connectionDetails,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<ViewCartPage> createState() => _ViewCartPageState();
}

class _ViewCartPageState extends State<ViewCartPage> {
  final TextEditingController _nameController =
      TextEditingController(text: 'PJ');
  bool _isLoading = false;
  bool _isConnected = false;
  StreamSubscription<bool>? _connectionSubscription;
  final ConnectionService _connectionService = ConnectionService();
  List<Map<String, dynamic>> _cartItems = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cartItems = List.from(widget.cartItems);
    _initConnection();
  }

  void _initConnection() {
    // Set up connection listener
    _connectionSubscription?.cancel();
    _connectionSubscription =
        _connectionService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          if (!connected) {
            _errorMessage = 'Not connected to server. Please connect first.';
          } else {
            _errorMessage = null;
          }
        });
      }
    });

    // Check if already connected to the same server
    if (_connectionService.isConnected &&
        _connectionService.currentIp == widget.connectionDetails['ip'] &&
        _connectionService.currentPort ==
            int.parse(widget.connectionDetails['port'])) {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _errorMessage = null;
        });
      }
      return;
    }

    // Try to connect if not already connected
    try {
      _connectionService.connect(
        widget.connectionDetails['ip'],
        int.parse(widget.connectionDetails['port']),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _errorMessage = 'Failed to connect: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _handleCheckout() async {
    if (!_isConnected) {
      setState(() {
        _errorMessage = 'Not connected to server. Please connect first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create SavedCartItem
      final savedCartItem = {
        'GuidId': const Uuid().v4(),
        'Name': 'PJ',
        'Comments': '', // Empty comments as per requirement
        'cartitem': _cartItems
            .map((item) => {
                  'ProductName': item['ProductName'],
                  'Price': item['Price'],
                  'quantity': item['quantity'],
                  'ImgUrl': item['ImgUrl'],
                  'modifiers': item['modifiers'],
                  'notes': item['notes'],
                })
            .toList(),
        'SavedDate': DateTime.now().toIso8601String(),
        'SavedBy': 'PJ',
        'SavedByUserId': 'user_${const Uuid().v4()}',
        'TodaysOrderNo': DateTime.now().millisecondsSinceEpoch.toString(),
        'OpenTicketStatusId': 1,
        'Total': widget.totalAmount,
        'IsDeleted': false,
        'DeletedBy': '',
        'IsSynced': false,
        'IsBillPrinted': false,
        'IsOSPrinted': false,
        'IsMerged': false,
        'MergedChildTables': [],
        'TextDuration': '',
        'CartOrderNo': '',
      };

      // Create the request in the format expected by Java server
      final requestMap = {
        'RequestType': 1,
        'MethodName': 'newOrder',
        'SavedCartItems': savedCartItem,
      };

      // Debug print the request
      debugPrint('=== Order Request Details ===');
      debugPrint('Request Type: ${requestMap['RequestType']}');
      debugPrint('Method Name: ${requestMap['MethodName']}');
      debugPrint('Saved Cart Item:');
      debugPrint('  - GUID: ${savedCartItem['GuidId']}');
      debugPrint('  - Name: ${savedCartItem['Name']}');
      debugPrint('  - Comments: ${savedCartItem['Comments']}');
      debugPrint('  - Total: ${savedCartItem['Total']}');
      final cartItems = savedCartItem['cartitem'] as List;
      debugPrint('  - Cart Items Count: ${cartItems.length}');
      debugPrint('  - Cart Items:');
      for (var item in cartItems) {
        debugPrint(
            '    * ${item['ProductName']} - ₱${item['Price']} x ${item['quantity']}');
        if (item['modifiers'] != null) {
          debugPrint('      Modifiers:');
          for (var mod in item['modifiers']) {
            debugPrint('        • ${mod['Name']} - ₱${mod['Price']}');
          }
        }
        if (item['notes'] != null && item['notes'].isNotEmpty) {
          debugPrint('      Notes: ${item['notes']}');
        }
      }
      debugPrint('===========================');

      // Convert to JSON and send
      final jsonString = jsonEncode(requestMap);
      debugPrint('JSON being sent: $jsonString');
      final bytes = utf8.encode(jsonString);

      // Send the request
      final socket = _connectionService.socket;
      if (socket == null) {
        throw Exception(
            'Socket is not available. Please connect to the server first.');
      }

      if (!_connectionService.isConnected) {
        throw Exception(
            'Socket connection is closed. Please reconnect to the server.');
      }

      try {
        // Send ObjectOutputStream header first
        final header = ByteData(4)
          ..setUint8(0, 0xac) // STREAM_MAGIC
          ..setUint8(1, 0xed) // STREAM_MAGIC
          ..setUint8(2, 0x00) // STREAM_VERSION
          ..setUint8(3, 0x05); // STREAM_VERSION

        debugPrint('Sending header: ${header.buffer.asUint8List()}');
        socket.add(header.buffer.asUint8List());
        await socket.flush();

        // Send the actual data
        debugPrint('Sending data bytes: ${bytes.length} bytes');
        socket.add(bytes);
        await socket.flush();

        // Wait for a short time to ensure the data is sent
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order sent successfully')),
          );
          Navigator.pop(context, _cartItems);
        }
      } catch (e) {
        debugPrint('Error sending data: $e');
        throw Exception('Failed to send data: $e');
      }
    } catch (e) {
      debugPrint('Error during checkout: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send order: ${e.toString()}';
        });
        // Try to reconnect
        _initConnection();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editCartItem(int index) async {
    final item = _cartItems[index];
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CustomizeOrderPanel(
        itemDetails: {
          'itemVariants': item['itemVariants'] ?? [],
          'itemModifiers': item['itemModifiers'] ?? [],
        },
        product: {
          'ProductName': item['ProductName'],
          'Price': item['Price'],
          'ImgUrl': item['ImgUrl'],
          'Id': item['Id'],
        },
      ),
    );

    if (result != null) {
      setState(() {
        _cartItems[index] = {
          ...item,
          'quantity': result['quantity'],
          'notes': result['notes'],
          'modifiers': result['modifiers'],
          'selectedVariant': result['variantId'],
          'variantDetails': result['variantDetails'],
          'Price': result['price'],
        };
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _connectionSubscription?.cancel();
    // Don't close the socket here, let the ConnectionService handle it
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Cart'),
        backgroundColor: AppColors.jet,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(
                    connectionDetails: widget.connectionDetails,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initConnection,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade100,
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade900),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return CartItem(
                  name: item['ProductName'] ?? 'Unnamed Item',
                  price: item['Price'] ?? 0.0,
                  quantity: item['quantity'] ?? 1,
                  imageUrl: item['ImgUrl'],
                  modifiers: item['modifiers'],
                  notes: item['notes'],
                  onEdit: () => _editCartItem(index),
                  onDelete: () {
                    setState(() {
                      _cartItems.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Total Amount: ₱${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCheckout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          _isConnected ? AppColors.jet : Colors.grey,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Checkout',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
