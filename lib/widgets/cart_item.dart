import 'package:flutter/material.dart';

class CartItem extends StatelessWidget {
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final List<Map<String, dynamic>>? modifiers;
  final String? notes;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CartItem({
    super.key,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.modifiers,
    this.notes,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl!.startsWith('file:///')
                          ? 'https://sellercenter.shoppazing.com/api/${imageUrl!.substring(8)}'
                          : imageUrl!.startsWith('http')
                              ? imageUrl!
                              : 'https://sellercenter.shoppazing.com/api/$imageUrl',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        );
                      },
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quantity: $quantity',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${(price * quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  Row(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: onEdit,
                          color: Colors.blue,
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: onDelete,
                          color: Colors.red,
                        ),
                    ],
                  ),
              ],
            ),
            if (modifiers != null && modifiers!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Modifiers:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...modifiers!.map((modifier) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      '• ${modifier['Name']} - ₱${modifier['Price']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  )),
            ],
            if (notes != null && notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Notes:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  notes!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
