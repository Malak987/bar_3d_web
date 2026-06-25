import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'pickup_info.dart';

class BottomBar extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback? onPickup;
  final PickupInfo? pickupInfo;

  const BottomBar({super.key, required this.onDownload, this.onPickup, this.pickupInfo});

  @override
  Widget build(BuildContext context) {
    final hasPickup = onPickup != null && pickupInfo != null;
    final info = pickupInfo ?? const PickupInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const _PriceBlock(),
          const SizedBox(width: 12),
          if (hasPickup) ...[Flexible(child: _PickupButton(info: info, onTap: onPickup!)), const SizedBox(width: 12)],
          Flexible(flex: 2, child: _CartButton(onTap: onDownload)),
        ]),
        if (hasPickup && info.hasBranch) ...[const SizedBox(height: 12), _PickupSummary(info: info)],
      ]),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Text('TOTAL EST.', style: TextStyle(color: AppColors.textLight, fontSize: 10, fontWeight: FontWeight.w600)),
      SizedBox(height: 4),
      Text('\$85.00', style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w900)),
    ],
  );
}

class _PickupButton extends StatelessWidget {
  final PickupInfo info;
  final VoidCallback onTap;
  const _PickupButton({required this.info, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final active = info.hasBranch;
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.teal.withOpacity(0.1) : AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? AppColors.teal : AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.calendar_month, size: 16, color: active ? AppColors.teal : AppColors.primary),
        const SizedBox(width: 6),
        Text(active ? 'محدد' : 'استلام', style: TextStyle(color: active ? AppColors.teal : AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    ));
  }
}

class _CartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CartButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFE8631A), Color(0xFFD4531A)]),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: const Color(0xFFE8631A).withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
    ),
    child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.shopping_cart_outlined, size: 18, color: Colors.white),
      SizedBox(width: 6),
      Text('Add to Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
    ])),
  ));
}

class _PickupSummary extends StatelessWidget {
  final PickupInfo info;
  const _PickupSummary({required this.info});
  @override
  Widget build(BuildContext context) {
    final d = info.date;
    final ds = d != null ? '${d.day}/${d.month}/${d.year}' : '';
    return Container(
      padding: const EdgeInsets.all(10), width: double.infinity,
      decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.teal.withOpacity(0.2))),
      child: Text('${info.branch} • $ds ${info.time ?? ''}', style: const TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
    );
  }
}
