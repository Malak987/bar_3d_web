import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_colors.dart';
import '../cubit/customization_orders_cubit.dart';
import '../data/customization_models.dart';
import 'customization_order_details_page.dart';

class CustomizationOrdersPage extends StatelessWidget {
  const CustomizationOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomizationOrdersCubit()..load(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            elevation: 0,
            title: const Text(
              'My Customized Orders',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: BlocBuilder<CustomizationOrdersCubit, CustomizationOrdersState>(
            builder: (context, state) {
              if (state is CustomizationOrdersLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.teal));
              }
              if (state is CustomizationOrdersError) {
                return _Error(
                  message: state.message,
                  onRetry: () => context.read<CustomizationOrdersCubit>().load(),
                );
              }
              if (state is CustomizationOrdersLoaded) {
                if (state.orders.isEmpty) return const _EmptyOrders();
                return RefreshIndicator(
                  onRefresh: () => context.read<CustomizationOrdersCubit>().load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _OrderCard(order: state.orders[i]),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final CustomizationOrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CustomizationOrderDetailsPage(order: order)),
      ),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [AppColors.cardShadow],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            final imageSize = compact ? 74.0 : 88.0;
            return Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: ColoredBox(
                      color: AppColors.bg,
                      child: order.designImageUrl.isEmpty
                          ? const Icon(Icons.cake_outlined, color: AppColors.textLight)
                          : Image.network(
                        order.designImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderNumber.isEmpty ? order.id : order.orderNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Chip(order.status, color: AppColors.teal),
                          _Chip(order.isDelivery ? 'Delivery' : 'Pickup', color: AppColors.orange),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.date.isEmpty ? '-' : order.date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${order.total.toStringAsFixed(0)} EGP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                if (!compact) const Icon(Icons.chevron_left, color: AppColors.textLight),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'لا توجد طلبات مخصصة حتى الآن',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Error({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 46),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
