import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_colors.dart';
import '../cubit/customization_checkout_cubit.dart';
import '../data/customization_models.dart';
import 'customization_orders_page.dart';

class CustomizationCheckoutPage extends StatefulWidget {
  final CustomizationCartModel cart;
  const CustomizationCheckoutPage({super.key, required this.cart});

  @override
  State<CustomizationCheckoutPage> createState() => _CustomizationCheckoutPageState();
}

class _CustomizationCheckoutPageState extends State<CustomizationCheckoutPage> {
  bool _delivery = false;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 12, minute: 0);
  final _branch = TextEditingController();
  final _address = TextEditingController();
  final _mapLocation = TextEditingController();
  final _note = TextEditingController();
  final _deliveryFee = TextEditingController(text: '0');
  final _discount = TextEditingController(text: '0');

  @override
  void dispose() {
    _branch.dispose(); _address.dispose(); _mapLocation.dispose(); _note.dispose(); _deliveryFee.dispose(); _discount.dispose();
    super.dispose();
  }

  double get deliveryFee => _delivery ? (double.tryParse(_deliveryFee.text) ?? 0) : 0;
  double get discount => double.tryParse(_discount.text) ?? 0;
  double get finalTotal => (widget.cart.subtotal + deliveryFee - discount).clamp(0, double.infinity).toDouble();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomizationCheckoutCubit(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocListener<CustomizationCheckoutCubit, CustomizationCheckoutState>(
          listener: (context, state) {
            if (state is CustomizationCheckoutSuccess) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CustomizationOrderSuccessPage(orderId: state.orderId, previewUrl: widget.cart.items.isNotEmpty ? widget.cart.items.first.designImageUrl : '')));
            }
            if (state is CustomizationCheckoutError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(backgroundColor: Colors.white, foregroundColor: AppColors.primary, elevation: 0, title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w900))),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(title: 'Step 1 — Delivery Type', child: Row(children: [
                  Expanded(child: _Choice(selected: !_delivery, icon: Icons.storefront, label: 'Pickup', onTap: () => setState(() => _delivery = false))),
                  const SizedBox(width: 10),
                  Expanded(child: _Choice(selected: _delivery, icon: Icons.delivery_dining, label: 'Delivery', onTap: () => setState(() => _delivery = true))),
                ])),
                const SizedBox(height: 12),
                if (!_delivery) _Section(title: 'Pickup Details', child: Column(children: [
                  _Field(controller: _branch, label: 'Branch Selector', icon: Icons.store),
                  _DateTimeTile(date: _date, time: _time, onTap: _pickDateTime),
                ])) else _Section(title: 'Delivery Details', child: Column(children: [
                  _Field(controller: _address, label: 'Address', icon: Icons.home),
                  _Field(controller: _mapLocation, label: 'Map Location / Coordinates', icon: Icons.location_on),
                  _Field(controller: _deliveryFee, label: 'Delivery Fee', icon: Icons.payments, keyboard: TextInputType.number, onChanged: (_) => setState(() {})),
                  _DateTimeTile(date: _date, time: _time, onTap: _pickDateTime),
                ])),
                const SizedBox(height: 12),
                _Section(title: 'Order Summary', child: Column(children: [
                  if (widget.cart.items.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(widget.cart.items.first.designImageUrl, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 160, color: AppColors.bg, child: const Icon(Icons.cake_outlined)))),
                  const SizedBox(height: 12),
                  _SummaryRow('Quantity', '${widget.cart.items.fold<int>(0, (s, i) => s + i.quantity)}'),
                  _SummaryRow('Total Price', '${widget.cart.subtotal.toStringAsFixed(0)} EGP'),
                  _SummaryRow('Delivery Fee', '${deliveryFee.toStringAsFixed(0)} EGP'),
                  _Field(controller: _discount, label: 'Discount', icon: Icons.discount, keyboard: TextInputType.number, onChanged: (_) => setState(() {})),
                  const Divider(height: 26),
                  _SummaryRow('Final Total', '${finalTotal.toStringAsFixed(0)} EGP', strong: true),
                  _Field(controller: _note, label: 'Order Note', icon: Icons.note_alt, maxLines: 2),
                ])),
                const SizedBox(height: 90),
              ],
            ),
            bottomNavigationBar: BlocBuilder<CustomizationCheckoutCubit, CustomizationCheckoutState>(
              builder: (context, state) => Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                color: Colors.white,
                child: SizedBox(height: 52, child: ElevatedButton(
                  onPressed: state is CustomizationCheckoutLoading ? null : () => _placeOrder(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                  child: state is CustomizationCheckoutLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Place Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                )),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: _time);
    setState(() { _date = d; if (t != null) _time = t; });
  }

  void _placeOrder(BuildContext context) {
    if (_delivery && _address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب عنوان التوصيل'), backgroundColor: Colors.orange));
      return;
    }
    if (!_delivery && _branch.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب أو اختر الفرع'), backgroundColor: Colors.orange));
      return;
    }
    context.read<CustomizationCheckoutCubit>().placeOrder({
      'deliveryType': _delivery ? 'Delivery' : 'Pickup',
      'branchId': _delivery ? null : _branch.text.trim(),
      'address': _delivery ? _address.text.trim() : null,
      'mapLocation': _delivery ? _mapLocation.text.trim() : null,
      'date': _date.toIso8601String().split('T').first,
      'time': '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
      'deliveryFee': deliveryFee,
      'discount': discount,
      'finalTotal': finalTotal,
      'note': _note.text.trim(),
    });
  }
}

class CustomizationOrderSuccessPage extends StatelessWidget {
  final String orderId;
  final String previewUrl;
  const CustomizationOrderSuccessPage({super.key, required this.orderId, required this.previewUrl});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 96, height: 96, decoration: BoxDecoration(color: AppColors.teal.withOpacity(.12), shape: BoxShape.circle), child: const Icon(Icons.check_circle, color: AppColors.teal, size: 70)),
          const SizedBox(height: 18),
          const Text('تم إنشاء الطلب بنجاح', style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Order Number: ${orderId.isEmpty ? '-' : orderId}', style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (previewUrl.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(previewUrl, height: 190, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('Back To Home'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal), onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CustomizationOrdersPage())), child: const Text('View My Orders', style: TextStyle(color: Colors.white)))),
          ]),
        ]),
      )),
    ),
  );
}

class _Section extends StatelessWidget { final String title; final Widget child; const _Section({required this.title, required this.child}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [AppColors.cardShadow]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)), const SizedBox(height: 12), child])); }
class _Choice extends StatelessWidget { final bool selected; final IconData icon; final String label; final VoidCallback onTap; const _Choice({required this.selected, required this.icon, required this.label, required this.onTap}); @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: selected ? AppColors.teal.withOpacity(.10) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? AppColors.teal : AppColors.border, width: selected ? 2 : 1)), child: Column(children: [Icon(icon, color: selected ? AppColors.teal : AppColors.primary), const SizedBox(height: 6), Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900))]))); }
class _Field extends StatelessWidget { final TextEditingController controller; final String label; final IconData icon; final TextInputType? keyboard; final int maxLines; final ValueChanged<String>? onChanged; const _Field({required this.controller, required this.label, required this.icon, this.keyboard, this.maxLines = 1, this.onChanged}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: controller, keyboardType: keyboard, maxLines: maxLines, onChanged: onChanged, decoration: InputDecoration(prefixIcon: Icon(icon, color: AppColors.teal), labelText: label, filled: true, fillColor: AppColors.bg.withOpacity(.55), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border))))); }
class _DateTimeTile extends StatelessWidget { final DateTime date; final TimeOfDay time; final VoidCallback onTap; const _DateTimeTile({required this.date, required this.time, required this.onTap}); @override Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.event_available, color: AppColors.teal), title: Text('${date.year}-${date.month}-${date.day}  ${time.format(context)}'), trailing: const Icon(Icons.edit_calendar), onTap: onTap); }
class _SummaryRow extends StatelessWidget { final String l; final String v; final bool strong; const _SummaryRow(this.l, this.v, {this.strong = false}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Expanded(child: Text(l, style: TextStyle(color: strong ? AppColors.primary : AppColors.textLight, fontWeight: FontWeight.w800))), Text(v, style: TextStyle(color: strong ? AppColors.teal : AppColors.primary, fontSize: strong ? 18 : 14, fontWeight: FontWeight.w900))])); }
