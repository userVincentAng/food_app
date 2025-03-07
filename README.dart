import 'package:flutter/material.dart';
import 'package:food_app/color.dart';
import 'package:food_app/pages/welcome_page.dart';
import '../api_service.dart';
import 'carousel_img.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  // Existing code...

  @override
  Widget build(BuildContext context) {
    // Existing code...
  }
}

class CustomizeOrderPanel extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onAddToOrder;

  const CustomizeOrderPanel({
    required this.product,
    required this.onAddToOrder,
    super.key,
  });

  @override
  _CustomizeOrderPanelState createState() => _CustomizeOrderPanelState();
}

class _CustomizeOrderPanelState extends State<CustomizeOrderPanel> {
  String? selectedVariant;
  List<String> selectedModifiers = [];

  Map<String, List<String>> categoryModifiers = {
    'sandwiches': ['Mayo Sauce', 'BBQ Sauce', 'Mustard', 'Ketchup'],
    'coffee': ['Extra Shot', 'Cream', 'Sugar', 'Honey'],
    'meals': ['Extra Rice', 'Extra Sauce', 'No Spice', 'Extra Spice'],
    'drinks': ['No Ice', 'Less Ice', 'Extra Ice'],
    'pasta': ['Extra Cheese', 'Extra Sauce', 'No Meat', 'Extra Meat'],
  };

  Map<String, List<String>> categoryVariants = {
    'coffee': ['Small', 'Medium', 'Large'],
    'meals': ['Regular', 'Large'],
    'drinks': ['330ml', '500ml', '1L'],
    'pasta': ['Half Portion', 'Full Portion'],
  };

  @override
  Widget build(BuildContext context) {
    final hasVariant = widget.product['hasVariant'];
    final hasModifiers = widget.product['hasModifiers'];
    final category = widget.product['category'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.product['name'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Image.network(
            widget.product['image'],
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, color: Colors.red);
            },
          ),
          const SizedBox(height: 10),
          if (hasVariant) ...[
            const Text(
              'Choose Size:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            DropdownButton<String>(
              value: selectedVariant,
              hint: const Text('Select a size'),
              onChanged: (String? newValue) {
                setState(() {
                  selectedVariant = newValue;
                });
              },
              items: categoryVariants[category]?.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
          if (hasModifiers) ...[
            const Text(
              'Add Modifiers:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Wrap(
              children: categoryModifiers[category]?.map((modifier) {
                return FilterChip(
                  label: Text(modifier),
                  selected: selectedModifiers.contains(modifier),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        selectedModifiers.add(modifier);
                      } else {
                        selectedModifiers.remove(modifier);
                      }
                    });
                  },
                );
              }).toList() ?? [],
            ),
            const SizedBox(height: 10),
          ],
          const Text(
            'Add Notes:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Enter your notes...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              widget.product['notes'] = value;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              widget.product['variant'] = selectedVariant;
              widget.product['modifiers'] = selectedModifiers;
              widget.onAddToOrder(widget.product);
              Navigator.pop(context);
            },
            child: const Text('Add to Order'),
          ),
        ],
      ),
    );
  }
}
