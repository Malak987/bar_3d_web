import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../data/customization_models.dart';

class CustomizationOrderDetailsPage extends StatelessWidget {
  final CustomizationOrderModel order;
  const CustomizationOrderDetailsPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final raw = order.raw;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(backgroundColor: Colors.white, foregroundColor: AppColors.primary, elevation: 0, title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.w900))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(height: 240, width: double.infinity, color: AppColors.bg, child: order.designImageUrl.isEmpty ? const Icon(Icons.cake_outlined, size: 60, color: AppColors.textLight) : Image.network(order.designImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)))),
              const SizedBox(height: 14),
              Text('#${order.orderNumber.isEmpty ? order.id : order.orderNumber}', style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Row(children: [_Status(order.status), const SizedBox(width: 8), _Status(order.isDelivery ? 'Delivery' : 'Pickup', orange: true)]),
            ])),
            const SizedBox(height: 12),
            _Panel(title: 'Order Information', child: Column(children: [
              _Row('Order ID', order.id),
              _Row('Date', order.date),
              _Row('Pickup/Delivery', order.isDelivery ? 'Delivery' : 'Pickup'),
              _Row('Total', '${order.total.toStringAsFixed(0)} EGP'),
            ])),
            const SizedBox(height: 12),
            _Panel(title: 'Customization Information', child: Column(children: _rawRows(raw))),
            const SizedBox(height: 12),
            _Panel(title: 'Timeline / Status', child: Column(children: [
              _Timeline('Order placed', true),
              _Timeline('Confirmed', _active(order.status, ['confirmed', 'preparing', 'ready', 'completed'])),
              _Timeline('Preparing', _active(order.status, ['preparing', 'ready', 'completed'])),
              _Timeline('Ready / Delivered', _active(order.status, ['ready', 'completed', 'delivered'])),
            ])),
            const SizedBox(height: 12),
            _Panel(title: 'Pricing Breakdown', child: Column(children: [
              _Row('Subtotal', '${_num(raw['subtotal'] ?? raw['totalPrice'] ?? raw['total']).toStringAsFixed(0)} EGP'),
              _Row('Delivery Fee', '${_num(raw['deliveryFee']).toStringAsFixed(0)} EGP'),
              _Row('Discount', '${_num(raw['discount']).toStringAsFixed(0)} EGP'),
              const Divider(),
              _Row('Final Total', '${order.total.toStringAsFixed(0)} EGP', strong: true),
            ])),
          ],
        ),
      ),
    );
  }

  List<Widget> _rawRows(Map<String, dynamic> raw) {
    final keys = ['shapeName', 'sizeName', 'flavorName', 'customMessage', 'note', 'photoUrl'];
    final rows = keys.where((k) => (raw[k]?.toString().trim().isNotEmpty ?? false)).map((k) => _Row(k, raw[k].toString())).toList();
    if (rows.isEmpty) rows.add(const _Row('Details', 'No extra customization details returned from API'));
    return rows;
  }

  bool _active(String status, List<String> values) => values.contains(status.toLowerCase());
  double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
}

class _Panel extends StatelessWidget { final String? title; final Widget child; const _Panel({this.title, required this.child}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [AppColors.cardShadow]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (title != null) ...[Text(title!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)), const SizedBox(height: 12)], child])); }
class _Row extends StatelessWidget { final String l; final String v; final bool strong; const _Row(this.l, this.v, {this.strong = false}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text(l, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800))), Expanded(child: Text(v.isEmpty ? '-' : v, style: TextStyle(color: strong ? AppColors.teal : AppColors.primary, fontWeight: strong ? FontWeight.w900 : FontWeight.w700)))])); }
class _Status extends StatelessWidget { final String text; final bool orange; const _Status(this.text, {this.orange = false}); @override Widget build(BuildContext context) { final c = orange ? AppColors.orange : AppColors.teal; return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: c.withOpacity(.1), borderRadius: BorderRadius.circular(999)), child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w900))); } }
class _Timeline extends StatelessWidget { final String text; final bool active; const _Timeline(this.text, this.active); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, color: active ? AppColors.teal : AppColors.textLight), const SizedBox(width: 8), Text(text, style: TextStyle(color: active ? AppColors.primary : AppColors.textLight, fontWeight: FontWeight.w800))])); }
