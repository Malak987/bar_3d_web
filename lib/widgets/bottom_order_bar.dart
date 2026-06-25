import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class BottomOrderBar extends StatelessWidget {
  const BottomOrderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
         const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text('TOTAL EST.', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
               Text('\$85.00', style: TextStyle(color: AppColors.navy, fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            label: const Text('Add to Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              minimumSize: const Size(180, 60),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          )
        ],
      ),
    );
  }
}