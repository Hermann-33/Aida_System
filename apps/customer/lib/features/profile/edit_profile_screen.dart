import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/aida_colors.dart';
import '../../core/theme/aida_type.dart';
import '../../domain/model/member.dart';

/// Edits name, phone, birthday, and student/employee ID — the CUS-21 field
/// list plus one client-requested addition. Email and member code are shown
/// but not editable here: email is tied to login, and the member code is
/// documented as immutable (it's baked into the offline QR).
///
/// Saving is session-only, same as cart and favorites — there's no backend
/// yet to persist a real edit to. It applies via [memberEditsProvider],
/// which every screen that shows member details reads from, so the edit
/// shows up on Home and the membership card too, not just here.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.member});

  final Member member;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final _nameController = TextEditingController(text: widget.member.name);
  late final _phoneController = TextEditingController(
    text: widget.member.phone ?? '',
  );
  late final _idController = TextEditingController(
    text: widget.member.studentOrEmployeeId ?? '',
  );
  late DateTime? _birthday = widget.member.birthday;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: now,
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AidaColors.coffee,
                onPrimary: AidaColors.cream,
                surface: AidaColors.cardWhite,
                onSurface: AidaColors.textPrimary,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  void _save() {
    final name = _nameController.text.trim();
    final edited = widget.member.copyWith(
      name: name.isEmpty ? widget.member.name : name,
      phone: _phoneController.text.trim(),
      birthday: _birthday,
      studentOrEmployeeId: _idController.text.trim(),
    );
    ref.read(memberEditsProvider.notifier).apply(edited);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AidaColors.espresso,
          content: Text(
            'Profile updated',
            style: AidaType.sans(size: 13, color: AidaColors.cream),
          ),
        ),
      );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidaColors.latte,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(
              initial: widget.member.initial,
              onBack: () => Navigator.of(context).pop(),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AidaColors.cardWhite,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AidaColors.espresso.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Full name'),
                    _EditableField(
                      controller: _nameController,
                      hint: 'Your name',
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel('Phone'),
                    _EditableField(
                      controller: _phoneController,
                      hint: '+60 12-345 6789',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel('Birthday'),
                    _BirthdayField(date: _birthday, onTap: _pickBirthday),
                    const SizedBox(height: 18),
                    const _FieldLabel('Student / Employee ID'),
                    _EditableField(
                      controller: _idController,
                      hint: 'e.g. TP012345',
                    ),
                    const SizedBox(height: 26),
                    const _FieldLabel('Email'),
                    _ReadOnlyField(value: widget.member.email),
                    const SizedBox(height: 18),
                    const _FieldLabel('Member code'),
                    _ReadOnlyField(value: widget.member.memberCode),
                    const SizedBox(height: 8),
                    Text(
                      'Email and member code can\'t be changed here.',
                      style: AidaType.sans(
                        size: 11.5,
                        color: AidaColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AidaColors.coffee,
                          foregroundColor: AidaColors.cream,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: AidaType.sans(
                            size: 14.5,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static (non-collapsing) version of Profile's own header — a form page
/// doesn't scroll far enough to need the collapse animation, but the
/// gradient, avatar treatment, and Back bar match it directly.
class _Header extends StatelessWidget {
  const _Header({required this.initial, required this.onBack});

  final String initial;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AidaColors.coffeeLight, AidaColors.latte, AidaColors.latte],
          stops: const [0.0, 0.42, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chevron_left_rounded,
                        size: 26,
                        color: AidaColors.textPrimary,
                      ),
                      Text(
                        'Back',
                        style: AidaType.sans(
                          size: 16,
                          weight: FontWeight.w600,
                          color: AidaColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AidaColors.cardWhite,
                boxShadow: [
                  BoxShadow(
                    color: AidaColors.espresso.withValues(alpha: 0.1),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AidaType.serif(size: 32, color: AidaColors.coffee),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Edit Profile',
              style: AidaType.sans(
                size: 16,
                weight: FontWeight.w700,
                color: AidaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AidaType.sans(
          size: 12.5,
          weight: FontWeight.w700,
          color: AidaColors.textPrimary,
        ),
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AidaType.sans(size: 14, color: AidaColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AidaType.sans(size: 14, color: AidaColors.textMuted),
        filled: true,
        fillColor: AidaColors.cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AidaColors.latte.withValues(alpha: 0.8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AidaColors.latte.withValues(alpha: 0.8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AidaColors.coffee, width: 1.4),
        ),
      ),
    );
  }
}

class _BirthdayField extends StatelessWidget {
  const _BirthdayField({required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _label =>
      date == null
          ? 'Select date'
          : '${date!.day} ${_months[date!.month - 1]} ${date!.year}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AidaColors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AidaColors.latte.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _label,
                style: AidaType.sans(
                  size: 14,
                  color:
                      date == null
                          ? AidaColors.textMuted
                          : AidaColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_rounded,
              size: 17,
              color: AidaColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AidaColors.latte.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        value,
        style: AidaType.sans(size: 14, color: AidaColors.textMuted),
      ),
    );
  }
}
