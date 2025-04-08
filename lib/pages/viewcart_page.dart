import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:food_app/color.dart';
import 'package:food_app/models/ordering_device_request.dart';
import 'package:food_app/pages/home_page.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
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
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

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
      final savedCartItem = SavedCartItem(
        guidId: const Uuid().v4(),
        name: _nameController.text,
        comments: _commentsController.text,
        cartItems: _cartItems,
        savedDate: DateTime.now().toIso8601String(),
        savedBy: _nameController.text,
        savedByUserId: 'user_${const Uuid().v4()}',
        todaysOrderNo: DateTime.now().millisecondsSinceEpoch.toString(),
        openTicketStatusId: 1,
        total: widget.totalAmount,
      );

      // Create OrderingDeviceRequest
      final request = OrderingDeviceRequest(
        requestType: 1,
        savedCartItems: savedCartItem,
      );

      // Convert to JSON
      final jsonString = jsonEncode(request.toJson());
      final bytes = utf8.encode(jsonString);
      final lengthBytes = ByteData(4)..setInt32(0, bytes.length, Endian.big);

      _connectionService.socket?.add(lengthBytes.buffer.asUint8List());
      _connectionService.socket?.add(bytes);
      await _connectionService.socket?.flush();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order sent successfully')),
        );
        Navigator.pop(context, _cartItems);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send order: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentsController.dispose();
    _connectionSubscription?.cancel();
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
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commentsController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Comments',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
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
