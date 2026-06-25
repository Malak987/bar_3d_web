import 'package:flutter/material.dart';

import '../../models/cake_config.dart';

class TopNavbar extends StatelessWidget {
  const TopNavbar({
    super.key,
    required this.config,
    required this.onToggleRotate,
    required this.onScreenshot,
  });

  final CakeConfig config;
  final VoidCallback onToggleRotate;
  final VoidCallback onScreenshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xEE12151C),
        border: Border(bottom: BorderSide(color: Color(0xFF242936))),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: const Color(0x66F59E0B).withOpacity(0.4), blurRadius: 18)],
                ),
                alignment: Alignment.center,
                child: const Text('🎂', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'مصمم التورتة ثلاثي الأبعاد ',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '3D',
                        style: TextStyle(color: Color(0xFFFBBF24), fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  SizedBox(height: 3),
                  Text(
                    '١٧ نوع تزيين • تدرج لوني فائق • كتابة وصور بدقة عالية ٢٠٤٨ بكسل',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavButton(
                icon: config.autoRotate ? Icons.pause_rounded : Icons.play_arrow_rounded,
                label: config.autoRotate ? 'إيقاف الدوران' : 'دوران تلقائي',
                active: config.autoRotate,
                onTap: onToggleRotate,
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onScreenshot,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0x66F59E0B).withOpacity(0.35), blurRadius: 14)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, size: 18, color: Colors.black),
                      SizedBox(width: 6),
                      Text('حفظ الصورة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0x1AF59E0B) : const Color(0xFF1D222E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? const Color(0x66F59E0B) : const Color(0xFF2F3646)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? const Color(0xFFFCD34D) : const Color(0xFFD1D5DB)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: active ? const Color(0xFFFCD34D) : const Color(0xFFD1D5DB), fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
