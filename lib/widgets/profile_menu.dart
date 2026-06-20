import 'package:flutter/material.dart';

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

  void _showSheet(BuildContext context) {
    final profile = Store.instance.profile;
    final managerNameController =
        TextEditingController(text: profile?.name ?? '');
    UserRole role = profile?.role ?? UserRole.employee;
    Worker? selectedWorker;
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
                        SegmentedButton<UserRole>(
                          segments: const [
                            ButtonSegment(
                              value: UserRole.employee,
                              label: Text('Employee'),
                              icon: Icon(Icons.badge_outlined),
                            ),
                            ButtonSegment(
                              value: UserRole.manager,
                              label: Text('Manager'),
                              icon: Icon(Icons.insights_outlined),
                            ),
                          ],
                          selected: {role},
                          onSelectionChanged: (s) =>
                              setSheet(() => role = s.first),
                        ),
                        const SizedBox(height: 16),
                        if (role == UserRole.manager) ...[
                          TextField(
                            controller: managerNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration:
                                const InputDecoration(labelText: 'Your name'),
                          ),
                        ] else ...[
                          const Text('Your name',
                              style: TextStyles.subheading),
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
                                    onTap: () =>
                                        setSheet(() => selectedWorker = w),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              w.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: selectedWorker?.id == w.id
                                                    ? Colors.white
                                                    : AppColors.navy,
                                              ),
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
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (role == UserRole.manager) {
                              final name = managerNameController.text.trim();
                              if (name.isEmpty) return;
                              await Store.instance.saveProfile(
                                Profile(name: name, role: role),
                              );
                            } else {
                              if (selectedWorker == null) return;
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
