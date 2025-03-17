import 'package:flutter/material.dart';

class CustomizeOrderPanel extends StatefulWidget {
  final Map<String, dynamic> itemDetails;
  final Map<String, dynamic> product;

  const CustomizeOrderPanel({super.key, required this.itemDetails, required this.product});

  @override
  CustomizeOrderPanelState createState() => CustomizeOrderPanelState();
}

class CustomizeOrderPanelState extends State<CustomizeOrderPanel> {
  int? selectedVariant; // Store SKUId
  Map<int, Map<String, dynamic>> selectedModifiers = {}; // Track selected modifiers with their details
  final TextEditingController _notesController = TextEditingController(); // Controller for notes

  @override
  void dispose() {
    _notesController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var variants = widget.itemDetails['itemVariants'] ?? [];
    var modifiers = widget.itemDetails['itemModifiers'] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Variants Selection
            if (variants.isNotEmpty) ...[
              const Text(
                "Select Size",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...variants.map<Widget>((variant) {
                return RadioListTile<int>(
                  title: Text(
                    "${variant['CombiName']} - ₱${variant['Price']}",
                  ),
                  value: variant['SKUId'], // Store SKUId instead of name
                  groupValue: selectedVariant,
                  onChanged: (value) {
                    setState(() => selectedVariant = value);
                  },
                );
              }).toList(),
            ],

            // Modifiers Selection
            if (modifiers.isNotEmpty) ...[
              const Text(
                "Add Extras",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...modifiers
                  .map<Widget>(
                    (modifier) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modifier['ModifierName'] ?? "Extras",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...modifier['ModifierOptions']
                        .map<Widget>(
                          (option) => CheckboxListTile(
                        title: Text(
                          "${option['Name']} - ₱${option['Price']}",
                        ),
                        value: selectedModifiers.containsKey(option['Id']),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedModifiers[option['Id']] = option; // Add modifier details
                            } else {
                              selectedModifiers.remove(option['Id']); // Remove modifier
                            }
                          });
                        },
                      ),
                    )
                        .toList(),
                  ],
                ),
              )
                  .toList(),
            ],

            // Add Notes Section
            const SizedBox(height: 16),
            const Text(
              "Add Notes",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: "e.g., No ice, less sugar, etc.",
                border: OutlineInputBorder(),
              ),
              maxLines: 3, // Allow multiple lines for notes
            ),

            // Confirm Button
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Check if there are variants and none are selected
                if (variants.isNotEmpty && selectedVariant == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a size!')),
                  );
                  return;
                }

                // Calculate the total price
                double totalPrice = widget.itemDetails['Price'] ?? widget.product['Price'];

                // If a variant is selected, use its price
                if (selectedVariant != null) {
                  var selectedVariantDetails = variants.firstWhere(
                        (variant) => variant['SKUId'] == selectedVariant,
                    orElse: () => null,
                  );
                  if (selectedVariantDetails != null) {
                    totalPrice = selectedVariantDetails['Price'];
                  }
                }

                // Add the price of selected modifiers
                selectedModifiers.values.forEach((modifier) {
                  totalPrice += modifier['Price'];
                });

                // Return the selected variant, modifiers, notes, and total price
                Navigator.pop(context, {
                  'variantId': selectedVariant,
                  'modifiers': selectedModifiers.values.toList(), // Include modifier details
                  'notes': _notesController.text.trim(), // Include notes
                  'price': totalPrice, // Include the total price
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                "Add to Cart",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
