import 'package:flutter/material.dart';

import '../color.dart';

class OrderSummaryPanel extends StatelessWidget {
  final double totalAmount;
  final int totalItems;
  final List<Map<String, dynamic>> orderItems;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  const OrderSummaryPanel({
    super.key,
    required this.totalAmount,
    required this.totalItems,
    required this.orderItems,
    required this.onCancel,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order Details Box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black54, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order Summary",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Total: ₱ ${totalAmount.toStringAsFixed(2)}  |  Items: $totalItems",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to cart screen
                  },
                  child: Icon(Icons.shopping_cart, color: AppColors.airforceBlue, size: 25,),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Buttons Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.flame,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text("Cancel Order", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.airforceBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text("Done", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
