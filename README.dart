import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Cart'),
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
                    title: Text(item['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Variant: ${item['variant'] ?? 'N/A'}'),
                        Text('Modifiers: ${item['modifiers']?.join(', ') ?? 'N/A'}'),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
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
