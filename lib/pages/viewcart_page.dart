import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_app/color.dart';
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

    // If connected to a different server, disconnect first
    if (_connectionService.isConnected) {
      _connectionService.disconnect();
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

  Future<void> _initConnectionAsync() async {
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

    // If connected to a different server, disconnect first
    if (_connectionService.isConnected) {
      await _connectionService.disconnect();
    }

    // Try to connect if not already connected
    try {
      await _connectionService.connect(
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
      // Try to reconnect
      await _initConnectionAsync();
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

      // Always try to reconnect before sending data to ensure a fresh connection
      await _initConnectionAsync();

      // Check if reconnection was successful
      if (!_connectionService.isConnected) {
        throw Exception('Failed to connect to POS system');
      }

      // Send data using the ConnectionService
      final success = await _connectionService.sendDataToPOS(requestMap);

      if (!success) {
        throw Exception('Failed to send data to POS system');
      }

      // Wait for server response
      debugPrint('Waiting for server response...');
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order sent successfully')),
        );
        Navigator.pop(context, _cartItems);
      }
    } catch (e) {
      debugPrint('Error sending data: $e');
      setState(() {
        _errorMessage = 'Failed to send data: $e';
      });
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
          if (_errorMessage != null && !_isConnected)
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
                        : Text(
                            _isConnected ? 'Checkout' : 'Not Connected',
                            style: const TextStyle(color: Colors.white),
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
