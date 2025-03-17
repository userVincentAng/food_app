import 'package:flutter/material.dart';
import 'customize_order.dart'; // Ensure this import is correct

class ViewCartPage extends StatelessWidget {
  final List<Map<String, dynamic>> orderItems;
  final Function(int index, Map<String, dynamic> updatedItem) onUpdateItem;
  final Function(int index) onRemoveItem;
  final Function() onCheckout;

  const ViewCartPage({
    super.key,
    required this.orderItems,
    required this.onUpdateItem,
    required this.onRemoveItem,
    required this.onCheckout,
  });

  double _calculateTotalAmount() {
    return orderItems.fold(0.0, (sum, item) => sum + (item['price'] as num).toDouble() * (item['quantity'] as int));
  }

  int _calculateTotalItems() {
    return orderItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shopping_cart, size: 30),
            const SizedBox(width: 20),
            const Text('View Cart'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: orderItems.length,
              itemBuilder: (context, index) {
                final item = orderItems[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: item['image'] != null
                        ? Image.network(
                      item['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, color: Colors.red);
                      },
                    )
                        : const Icon(Icons.image, size: 50), // Fallback if no image URL
                    title: Text(item['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Variant: ${item['selectedVariant'] ?? 'N/A'}'),
                        Text('Modifiers: ${item['modifiers']?.map((mod) => mod['Name']).join(', ') ?? 'N/A'}'),
                        Text('Notes: ${item['notes'] ?? 'N/A'}'),
                        Text('Price: ₱${item['price'].toString()}'),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (item['quantity'] > 1) {
                                  final updatedItem = Map<String, dynamic>.from(item);
                                  updatedItem['quantity'] = item['quantity'] - 1;
                                  onUpdateItem(index, updatedItem);
                                } else {
                                  onRemoveItem(index);
                                }
                              },
                            ),
                            Text('${item['quantity']}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final updatedItem = Map<String, dynamic>.from(item);
                                updatedItem['quantity'] = item['quantity'] + 1;
                                onUpdateItem(index, updatedItem);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _editItem(context, item, index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 70,
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20.0),
            child: Row(
              children: [
                Text('Total Amount: ₱${_calculateTotalAmount().toStringAsFixed(2)}'),
                const SizedBox(width: 10),
                Text('|  Total Items: ${_calculateTotalItems()}'),
                const SizedBox(width: 20),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: ElevatedButton(
              onPressed: onCheckout,
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }

  void _editItem(BuildContext context, Map<String, dynamic> item, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CustomizeOrderPanel(
          itemDetails: item,
          product: item,
          onAddToOrder: (updatedItem) {
            onUpdateItem(index, updatedItem);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
