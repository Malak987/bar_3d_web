import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// Branch + date + time picker
class ModernPickupDialog extends StatefulWidget {
  final String? initialBranch;
  final DateTime? initialDate;
  final String? initialTime;
  final void Function(String, DateTime, String) onConfirm;

  const ModernPickupDialog({
    super.key,
    this.initialBranch,
    this.initialDate,
    this.initialTime,
    required this.onConfirm,
  });

  @override
  State<ModernPickupDialog> createState() => _ModernPickupDialogState();
}

class _ModernPickupDialogState extends State<ModernPickupDialog> {
  String? _branch;
  DateTime? _date;
  String? _time;

  static const _branches = [
    {'name': 'فرع الحميات',  'icon': Icons.local_hospital},
    {'name': 'فرع الزهراء',  'icon': Icons.home_work},
  ];

  static const _times = [
    '10:00 ص', '12:00 م', '02:00 م', '04:00 م', '06:00 م', '08:00 م',
  ];

  @override
  void initState() {
    super.initState();
    _branch = widget.initialBranch;
    _date   = widget.initialDate;
    _time   = widget.initialTime;
  }

  bool get _canConfirm => _branch != null && _date != null && _time != null;

  String _dayName(DateTime d) {
    const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء',
                  'الخميس', 'الجمعة', 'السبت'];
    return days[d.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('1. اختر الفرع'),
                      const SizedBox(height: 12),
                      _branchRow(),
                      const SizedBox(height: 24),
                      const _SectionTitle('2. تاريخ الاستلام'),
                      const SizedBox(height: 12),
                      _dateButton(),
                      const SizedBox(height: 24),
                      const _SectionTitle('3. الوقت المناسب'),
                      const SizedBox(height: 12),
                      _timesWrap(),
                      const SizedBox(height: 32),
                      _confirmButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.navy],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حجز استلام الطلب',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'اختر الوقت والمكان المناسب',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _branchRow() {
    return Row(
      children: _branches.map((branch) {
        final selected = _branch == branch['name'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _branch = branch['name'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    branch['icon'] as IconData,
                    color: selected ? Colors.white : AppColors.textLight,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    branch['name'] as String,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textMid,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dateButton() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _date != null ? AppColors.teal : AppColors.border,
            width: 2,
          ),
          boxShadow: _date != null
              ? [BoxShadow(color: AppColors.teal.withOpacity(0.2), blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: _date != null ? AppColors.teal : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _date != null
                        ? '${_date!.day}/${_date!.month}/${_date!.year}'
                        : 'اختر يوماً',
                    style: TextStyle(
                      color: _date != null ? AppColors.textMid : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (_date != null)
                    Text(
                      'يوم ${_dayName(_date!)}',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.teal),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _date = date);
  }

  Widget _timesWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _times.map((t) {
        final selected = _time == t;
        return GestureDetector(
          onTap: () => setState(() => _time = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.teal : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.teal : AppColors.border,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: AppColors.teal.withOpacity(0.4), blurRadius: 6)]
                  : null,
            ),
            child: Text(
              t,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textMid,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _confirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _canConfirm
            ? () => widget.onConfirm(_branch!, _date!, _time!)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          disabledBackgroundColor: Colors.grey[300],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: AppColors.orange.withOpacity(0.4),
        ),
        child: const Text(
          'تأكيد الحجز',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textMid,
          fontSize: 14,
        ),
      );
}
