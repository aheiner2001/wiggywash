import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/worker.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/brand_header.dart';

/// First-run screen: pick role, then enter name (manager) or select from the
/// manager's roster (employee).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _managerName = TextEditingController();
  UserRole _role = UserRole.employee;
  Worker? _selectedWorker;
  bool _attempted = false;

  @override
  void dispose() {
    _managerName.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() => _attempted = true);

    if (_role == UserRole.manager) {
      final name = _managerName.text.trim();
      if (name.isEmpty) return;
      await Store.instance.saveProfile(Profile(name: name, role: _role));
      return;
    }

    if (_selectedWorker == null) return;
    await Store.instance.saveProfile(
      Profile(name: _selectedWorker!.name, role: UserRole.employee),
    );
  }

  @override
  Widget build(BuildContext context) {
    final managerNameError =
        _attempted && _role == UserRole.manager && _managerName.text.trim().isEmpty;
    final employeeError =
        _attempted && _role == UserRole.employee && _selectedWorker == null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const BrandHeader(),
                  const SizedBox(height: 32),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("I'm a…", style: TextStyles.subheading),
                        const SizedBox(height: 10),
                        _RolePicker(
                          role: _role,
                          onChanged: (r) => setState(() {
                            _role = r;
                            _attempted = false;
                          }),
                        ),
                        const SizedBox(height: 22),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _role == UserRole.manager
                              ? _ManagerNameField(
                                  key: const ValueKey('manager'),
                                  controller: _managerName,
                                  error: managerNameError,
                                  onChanged: () => setState(() {}),
                                )
                              : _EmployeePicker(
                                  key: const ValueKey('employee'),
                                  selected: _selectedWorker,
                                  error: employeeError,
                                  onSelected: (w) =>
                                      setState(() => _selectedWorker = w),
                                ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _continue,
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _role == UserRole.employee
                        ? 'Pick the name your manager added for you.'
                        : 'Saved on this device — you can change it later.',
                    textAlign: TextAlign.center,
                    style: TextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagerNameField extends StatelessWidget {
  const _ManagerNameField({
    super.key,
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool error;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your name', style: TextStyles.subheading),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: 'e.g. Aaron',
            errorText: error ? 'Please enter your name' : null,
          ),
        ),
      ],
    );
  }
}

class _EmployeePicker extends StatelessWidget {
  const _EmployeePicker({
    super.key,
    required this.selected,
    required this.error,
    required this.onSelected,
  });

  final Worker? selected;
  final bool error;
  final ValueChanged<Worker> onSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Store.instance,
      builder: (context, _) {
        final workers = Store.instance.workers;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select your name', style: TextStyles.subheading),
            const SizedBox(height: 10),
            if (workers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  border: Border.all(
                    color: error ? AppColors.danger : AppColors.hairline,
                  ),
                ),
                child: const Text(
                  'No names on the roster yet. Ask your manager to add you first, then refresh this page.',
                  style: TextStyles.caption,
                ),
              )
            else
              ...workers.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected?.id == w.id
                        ? AppColors.navy
                        : AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      onTap: () => onSelected(w),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: selected?.id == w.id
                                  ? Colors.white
                                  : AppColors.navy,
                              child: Text(
                                w.name[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: selected?.id == w.id
                                      ? AppColors.navy
                                      : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                w.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: selected?.id == w.id
                                      ? Colors.white
                                      : AppColors.navy,
                                ),
                              ),
                            ),
                            if (selected?.id == w.id)
                              const Icon(Icons.check_rounded,
                                  color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (error && workers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Please select your name',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.role, required this.onChanged});
  final UserRole role;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleChip(
            label: 'Employee',
            icon: Icons.badge_outlined,
            selected: role == UserRole.employee,
            onTap: () => onChanged(UserRole.employee),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleChip(
            label: 'Manager',
            icon: Icons.insights_outlined,
            selected: role == UserRole.manager,
            onTap: () => onChanged(UserRole.manager),
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : AppColors.blueSoft,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : AppColors.navy,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
