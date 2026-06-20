import 'package:flutter/material.dart';

import '../config/auth_config.dart';
import '../models/profile.dart';
import '../models/worker.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/brand_header.dart';

/// First-run screen: employees pick their name (and optional code). Managers
/// sign in via a hidden link with the manager password.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _managerPassword = TextEditingController();
  final _employeePin = TextEditingController();

  bool _managerLogin = false;
  Worker? _selectedWorker;
  bool _attempted = false;
  String? _authError;

  @override
  void dispose() {
    _managerPassword.dispose();
    _employeePin.dispose();
    super.dispose();
  }

  void _selectWorker(Worker? worker) {
    setState(() {
      _selectedWorker = worker;
      _employeePin.clear();
      _authError = null;
    });
  }

  Future<void> _continue() async {
    setState(() {
      _attempted = true;
      _authError = null;
    });

    if (_managerLogin) {
      if (!verifyManagerPassword(_managerPassword.text)) {
        setState(() => _authError = 'Incorrect manager password');
        return;
      }
      await Store.instance.saveProfile(
        const Profile(name: kManagerDisplayName, role: UserRole.manager),
      );
      return;
    }

    if (_selectedWorker == null) return;

    if (_selectedWorker!.requiresPin) {
      if (!_selectedWorker!.verifyPin(_employeePin.text)) {
        setState(() => _authError = 'Incorrect entry code');
        return;
      }
    }

    await Store.instance.saveProfile(
      Profile(name: _selectedWorker!.name, role: UserRole.employee),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeeError =
        _attempted && !_managerLogin && _selectedWorker == null;
    final pinError = _attempted &&
        !_managerLogin &&
        _selectedWorker != null &&
        _selectedWorker!.requiresPin &&
        _employeePin.text.trim().isEmpty;

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
                        if (_managerLogin) ...[
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Back',
                                onPressed: () => setState(() {
                                  _managerLogin = false;
                                  _attempted = false;
                                  _authError = null;
                                }),
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                              const Expanded(
                                child: Text(
                                  'Manager sign in',
                                  style: TextStyles.subheading,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _managerPassword,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter password',
                              errorText: _authError,
                            ),
                            onChanged: (_) => setState(() => _authError = null),
                          ),
                        ] else ...[
                          _EmployeePicker(
                            selected: _selectedWorker,
                            error: employeeError,
                            pinController: _employeePin,
                            pinError: pinError || _authError == 'Incorrect entry code',
                            authError: _authError,
                            onSelected: _selectWorker,
                            onPinChanged: () => setState(() => _authError = null),
                          ),
                        ],
                        if (_authError != null &&
                            _authError != 'Incorrect entry code')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _authError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _continue,
                          child: Text(_managerLogin ? 'Open dashboard' : 'Continue'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_managerLogin)
                    TextButton(
                      onPressed: () => setState(() {
                        _managerLogin = true;
                        _attempted = false;
                        _authError = null;
                        _selectedWorker = null;
                        _employeePin.clear();
                      }),
                      child: const Text('Manager sign in'),
                    )
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 4),
                  Text(
                    _managerLogin
                        ? 'Manager access requires the team password.'
                        : 'Pick the name your manager added for you.',
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

class _EmployeePicker extends StatelessWidget {
  const _EmployeePicker({
    required this.selected,
    required this.error,
    required this.pinController,
    required this.pinError,
    required this.authError,
    required this.onSelected,
    required this.onPinChanged,
  });

  final Worker? selected;
  final bool error;
  final TextEditingController pinController;
  final bool pinError;
  final String? authError;
  final ValueChanged<Worker> onSelected;
  final VoidCallback onPinChanged;

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w.name,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: selected?.id == w.id
                                          ? Colors.white
                                          : AppColors.navy,
                                    ),
                                  ),
                                  if (w.requiresPin)
                                    Text(
                                      'Code required',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: selected?.id == w.id
                                            ? Colors.white70
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                ],
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
            if (selected?.requiresPin == true) ...[
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                onChanged: (_) => onPinChanged(),
                decoration: InputDecoration(
                  labelText: 'Entry code',
                  hintText: 'Enter code',
                  errorText: pinError ? 'Enter your code' : null,
                ),
              ),
              if (authError == 'Incorrect entry code')
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    authError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
