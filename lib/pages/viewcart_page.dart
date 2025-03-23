import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'dart:io';
import 'dart:convert';
import '../color.dart';
import 'customize_order.dart';

class ViewCartPage extends StatefulWidget {
  final List<Map<String, dynamic>> orderItems;
  final Function(List<Map<String, dynamic>>) onOrderUpdated;
  final Map<String, dynamic> connectionDetails; // Add connection details

  const ViewCartPage({
    super.key,
    required this.orderItems,
    required this.onOrderUpdated,
    required this.connectionDetails, // Pass connection details
  });

  @override
  ViewCartPageState createState() => ViewCartPageState();
}

class ViewCartPageState extends State<ViewCartPage> {
  late List<Map<String, dynamic>> orderItems;
  late String serverIP; // Use the passed IP
  late int serverPort; // Use the passed port

  @override
  void initState() {
    super.initState();
    orderItems = List.from(widget.orderItems); // Create a copy of the order items
    serverIP = widget.connectionDetails['ip']; // Initialize IP
    serverPort = widget.connectionDetails['port']; // Initialize port
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        orderItems[index]['quantity'] = newQuantity;
      });
    } else {
      // Remove item if quantity is 0
      setState(() {
        orderItems.removeAt(index);
      });
    }
    widget.onOrderUpdated(orderItems); // Notify parent of changes
  }

  void _editItem(int index) async {
    final item = orderItems[index];
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CustomizeOrderPanel(
        itemDetails: item,
        product: item,
      ),
    );

    if (result != null) {
      setState(() {
        orderItems[index] = {
          ...item,
          'imageUrl': result['imageUrl'],
          'selectedVariant': result['variantId'], // Store the selected variant name
          'modifiers': result['modifiers'],
          'notes': result['notes'],
          'Price': result['price']
        };
      });
      widget.onOrderUpdated(orderItems); // Notify parent of changes
    }
  }

  void _deleteItem(int index) {
    setState(() {
      orderItems.removeAt(index);
    });
    widget.onOrderUpdated(orderItems); // Notify parent of changes
  }

  double _calculateTotalAmount() {
    return orderItems.fold(0.0, (double sum, item) {
      final price = (item['Price'] as num? ?? 0).toDouble();
      final quantity = item['quantity'] as int? ?? 0;
      return sum + (price * quantity);
    });
  }

  Future<void> sendOrderDetails() async {
    final orderDetails = {
      'items': orderItems,
      'totalAmount': _calculateTotalAmount(),
    };

    // Convert the order details to JSON
    final jsonMessage = jsonEncode(orderDetails);

    try {
      final socket = await Socket.connect(serverIP, serverPort);
      print('Connected to server');

      // Send the JSON message
      socket.write(jsonMessage);
      print('Order details sent: $jsonMessage');

      await socket.flush();
      socket.destroy();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order sent successfully!')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'View Cart',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.airforceBlue,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orderItems.length,
              itemBuilder: (context, index) {
                final item = orderItems[index];
                final price = (item['Price'] as num? ?? 0).toDouble();
                final quantity = item['quantity'] as int? ?? 0;
                final totalPrice = price * quantity;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display the image if available
                        if (item['imageUrl'] != null)
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item['imageUrl'],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error, color: Colors.red);
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          item['ProductName'] ?? 'Unnamed Item',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (item['selectedVariant'] != null)
                          Text(
                            item['variantDetails']?['CombiName'] ?? 'No Size Selected',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        if (item['modifiers'] != null && item['modifiers'].isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              const Text(
                                'Modifiers:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              ...item['modifiers'].map<Widget>((modifier) {
                                return Text(
                                  '- ${modifier['Name']} (₱${modifier['Price']})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        if (item['notes'] != null && item['notes'].isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Notes: ${item['notes']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Quantity Selector
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.airforceBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 20),
                                    onPressed: () => _updateQuantity(index, quantity - 1),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    onPressed: () => _updateQuantity(index, quantity + 1),
                                  ),
                                ],
                              ),
                            ),
                            // Total Price
                            Text(
                              '₱${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Edit and Delete Icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit',
                              onPressed: () => _editItem(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () => _deleteItem(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Total Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₱${_calculateTotalAmount().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: sendOrderDetails, // Trigger order sending
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.airforceBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Checkout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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