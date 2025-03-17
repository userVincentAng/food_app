import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../color.dart';
import 'customize_order.dart';

class ViewCartPage extends StatefulWidget {
  final List<Map<String, dynamic>> orderItems;
  final Function(List<Map<String, dynamic>>) onOrderUpdated;

  const ViewCartPage({
    super.key,
    required this.orderItems,
    required this.onOrderUpdated,
  });

  @override
  ViewCartPageState createState() => ViewCartPageState();
}

class ViewCartPageState extends State<ViewCartPage> {
  late List<Map<String, dynamic>> orderItems;

  @override
  void initState() {
    super.initState();
    orderItems = List.from(widget.orderItems); // Create a copy of the order items
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
          'selectedVariant': result['variantId'],
          'modifiers': result['modifiers'],
          'notes': result['notes'],
          'Price': result['price'],
        };
      });
      widget.onOrderUpdated(orderItems); // Notify parent of changes
    }
  }

  double _calculateTotalAmount() {
    return orderItems.fold(0.0, (double sum, item) {
      final price = (item['Price'] as num? ?? 0).toDouble();
      final quantity = item['quantity'] as int? ?? 0;
      return sum + (price * quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Cart'),
        backgroundColor: AppColors.airforceBlue,
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
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['Name'] ?? 'Unnamed Item',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (item['selectedVariant'] != null)
                          Text(
                            'Variant: ${item['selectedVariant']}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        if (item['modifiers'] != null && item['modifiers'].isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Modifiers:',
                                style: TextStyle(color: Colors.grey),
                              ),
                              ...item['modifiers'].map<Widget>((modifier) {
                                return Text(
                                  '- ${modifier['Name']} (₱${modifier['Price']})',
                                  style: TextStyle(color: Colors.grey.shade600),
                                );
                              }).toList(),
                            ],
                          ),
                        if (item['notes'] != null && item['notes'].isNotEmpty)
                          Text(
                            'Notes: ${item['notes']}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _updateQuantity(index, quantity - 1),
                                ),
                                Text('$quantity'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _updateQuantity(index, quantity + 1),
                                ),
                              ],
                            ),
                            Text(
                              '₱${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _editItem(index),
                            child: const Text('Edit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
                  onPressed: () {
                    // Handle checkout logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.airforceBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Checkout', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
