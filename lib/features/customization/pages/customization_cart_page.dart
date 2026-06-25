import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_colors.dart';
import '../cubit/customization_cart_cubit.dart';
import '../data/customization_models.dart';
import 'customization_checkout_page.dart';
import 'customization_orders_page.dart';

class CustomizationCartPage extends StatelessWidget {
  const CustomizationCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomizationCartCubit()..load(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            elevation: 0,
            title: const Text('سلة التصميمات المخصصة', style: TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              IconButton(
                tooltip: 'طلباتي',
                icon: const Icon(Icons.receipt_long),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomizationOrdersPage())),
              ),
            ],
          ),
          body: BlocBuilder<CustomizationCartCubit, CustomizationCartState>(
            builder: (context, state) {
              if (state is CustomizationCartLoading) return const Center(child: CircularProgressIndicator(color: AppColors.teal));
              if (state is CustomizationCartError) return _ErrorView(message: state.message, onRetry: () => context.read<CustomizationCartCubit>().load());
              if (state is CustomizationCartLoaded) {
                if (state.cart.items.isEmpty) return const _EmptyCart();
                return _CartBody(cart: state.cart);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _CartBody extends StatelessWidget {
  final CustomizationCartModel cart;
  const _CartBody({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<CustomizationCartCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _CartItemCard(item: cart.items[i]),
            ),
          ),
        ),
        _StickyCheckoutBar(
          subtotal: cart.subtotal,
          onCheckout: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CustomizationCheckoutPage(cart: cart),
          )),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CustomizationCartItem item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [AppColors.cardShadow]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NetworkImageBox(url: item.designImageUrl, height: 210),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(item.shape.isEmpty ? 'تصميم كيك مخصص' : item.shape, style: const TextStyle(color: AppColors.primary, fontSize: 17, fontWeight: FontWeight.w900))),
                  Text('${item.totalPrice.toStringAsFixed(0)} EGP', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _InfoChip(Icons.straighten, 'المقاس: ${item.size.isEmpty ? '-' : item.size}'),
                  _InfoChip(Icons.icecream, 'النكهة: ${item.flavor.isEmpty ? '-' : item.flavor}'),
                  _InfoChip(Icons.format_list_numbered, 'الكمية: ${item.quantity}'),
                ]),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('تفاصيل التصميم', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                    children: [
                      _DetailRow('الألوان', item.colors.isEmpty ? '-' : item.colors.join(' / ')),
                      _DetailRow('التزيين', item.piping.isEmpty ? '-' : item.piping),
                      _DetailRow('Toppings', item.toppings.isEmpty ? '-' : item.toppings.join(', ')),
                      _DetailRow('Extras', item.extras.isEmpty ? '-' : item.extras.join(', ')),
                      _DetailRow('الرسالة', item.message.isEmpty ? '-' : item.message),
                      if (item.photoUrl.isNotEmpty) _DetailRow('صورة العميل', 'مرفوعة ✓'),
                    ],
                  ),
                ),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => context.read<CustomizationCartCubit>().remove(item.id),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
                  )),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyCheckoutBar extends StatelessWidget {
  final double subtotal;
  final VoidCallback onCheckout;
  const _StickyCheckoutBar({required this.subtotal, required this.onCheckout});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, -4))]),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('Subtotal', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800)),
          Text('${subtotal.toStringAsFixed(0)} EGP', style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w900)),
        ])),
        SizedBox(width: 170, height: 52, child: ElevatedButton(onPressed: onCheckout, style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal), child: const Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))),
      ]),
    );
  }
}

class _NetworkImageBox extends StatelessWidget {
  final String url;
  final double height;
  const _NetworkImageBox({required this.url, required this.height});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
    child: Container(
      height: height,
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.06),
      child: url.isEmpty
          ? const Icon(Icons.cake_outlined, size: 52, color: AppColors.textLight)
          : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 48)),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: AppColors.teal), const SizedBox(width: 5), Text(text, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700))]),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800))),
      Expanded(child: Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
    ]),
  );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.shopping_bag_outlined, size: 68, color: AppColors.textLight),
      const SizedBox(height: 12),
      const Text('لا توجد تصميمات في السلة', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ارجع للتصميم')),
    ]),
  ));
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 46),
      const SizedBox(height: 10),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
    ]),
  ));
}
