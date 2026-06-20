import 'package:flutter/material.dart';

import '../config/auth_config.dart';
import '../models/profile.dart';
import '../models/worker.dart';
import '../services/store.dart';
import '../theme.dart';

/// App-bar action that opens a sheet to switch name / role.
class ProfileAction extends StatelessWidget {
  const ProfileAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle_rounded),
      onPressed: () => _showSheet(context),
    );
  }

  Future<bool> _promptManagerPassword(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manager password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter password',
          ),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    final password = controller.text;
    controller.dispose();
    if (confirmed != true) return false;
    return verifyManagerPassword(password);
  }

  void _showSheet(BuildContext context) {
    final profile = Store.instance.profile;
    final employeePinController = TextEditingController();

    UserRole role = profile?.role ?? UserRole.employee;
    Worker? selectedWorker;
    String? authError;

    if (profile?.role == UserRole.employee) {
      final current = profile!.name;
      for (final w in Store.instance.workers) {
        if (w.name == current) {
          selectedWorker = w;
          break;
        }
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            18 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              return AnimatedBuilder(
                animation: Store.instance,
                builder: (context, _) {
                  final workers = Store.instance.workers;
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Account', style: TextStyles.heading),
                        const SizedBox(height: 16),
                        if (role == UserRole.manager) ...[
                          const Text(
                            'Signed in as manager',
                            style: TextStyles.body,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setSheet(() {
                              role = UserRole.employee;
                              authError = null;
                              employeePinController.clear();
                            }),
                            child: const Text('Switch to employee'),
                          ),
                        ] else ...[
                          const Text('Your name', style: TextStyles.subheading),
                          const SizedBox(height: 8),
                          if (workers.isEmpty)
                            const Text(
                              'No names on the roster yet. Ask your manager to add you.',
                              style: TextStyles.caption,
                            )
                          else
                            ...workers.map(
                              (w) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Material(
                                  color: selectedWorker?.id == w.id
                                      ? AppColors.navy
                                      : AppColors.blueSoft,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.button),
                                  child: InkWell(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.button),
                                    onTap: () => setSheet(() {
                                      selectedWorker = w;
                                      employeePinController.clear();
                                      authError = null;
                                    }),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  w.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: selectedWorker?.id ==
                                                            w.id
                                                        ? Colors.white
                                                        : AppColors.navy,
                                                  ),
                                                ),
                                                if (w.requiresPin)
                                                  Text(
                                                    'Code required',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: selectedWorker
                                                                  ?.id ==
                                                              w.id
                                                          ? Colors.white70
                                                          : AppColors.textMuted,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (selectedWorker?.id == w.id)
                                            const Icon(Icons.check_rounded,
                                                color: Colors.white, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (selectedWorker?.requiresPin == true) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: employeePinController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Entry code',
                                hintText: 'Enter code',
                                errorText: authError,
                              ),
                              onChanged: (_) =>
                                  setSheet(() => authError = null),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              final ok = await _promptManagerPassword(ctx);
                              if (!ctx.mounted) return;
                              if (!ok) {
                                setSheet(() =>
                                    authError = 'Incorrect manager password');
                                return;
                              }
                              setSheet(() {
                                role = UserRole.manager;
                                authError = null;
                              });
                            },
                            child: const Text('Manager sign in'),
                          ),
                        ],
                        if (authError != null &&
                            authError != 'Incorrect entry code')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              authError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (role == UserRole.manager) {
                              await Store.instance.saveProfile(
                                const Profile(
                                  name: kManagerDisplayName,
                                  role: UserRole.manager,
                                ),
                              );
                            } else {
                              if (selectedWorker == null) return;
                              if (selectedWorker!.requiresPin) {
                                if (!selectedWorker!
                                    .verifyPin(employeePinController.text)) {
                                  setSheet(() =>
                                      authError = 'Incorrect entry code');
                                  return;
                                }
                              }
                              await Store.instance.saveProfile(
                                Profile(
                                  name: selectedWorker!.name,
                                  role: role,
                                ),
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: const Text('Save'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            await Store.instance.clearProfile();
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: const Text('Sign out of this device'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
