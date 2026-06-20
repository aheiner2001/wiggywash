import 'package:flutter/material.dart';

import '../services/store.dart';
import '../theme.dart';

/// Manager screen for adding and removing employee names on the team roster.
class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final err = await Store.instance.addWorker(_name.text);
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    _name.clear();
    setState(() => _error = null);
  }

  Future<void> _remove(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove worker?'),
        content: Text('Remove $name from the team list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await Store.instance.removeWorker(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Roster')),
      body: AnimatedBuilder(
        animation: Store.instance,
        builder: (context, _) {
          final workers = Store.instance.workers;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Add a worker', style: TextStyles.subheading),
                        const SizedBox(height: 8),
                        const Text(
                          'Employees pick their name from this list when they sign in.',
                          style: TextStyles.caption,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'e.g. Jacob',
                            errorText: _error,
                          ),
                          onChanged: (_) {
                            if (_error != null) setState(() => _error = null);
                          },
                          onSubmitted: (_) => _add(),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _add,
                          icon: const Icon(Icons.person_add_rounded),
                          label: const Text('Add to roster'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (workers.isEmpty)
                    const AppCard(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No workers yet. Add names above — employees will choose from this list.',
                        textAlign: TextAlign.center,
                        style: TextStyles.caption,
                      ),
                    )
                  else
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Text(
                              '${workers.length} on roster',
                              style: TextStyles.caption,
                            ),
                          ),
                          for (final w in workers)
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.navy,
                                child: Text(
                                  w.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              title: Text(
                                w.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing: IconButton(
                                tooltip: 'Remove',
                                icon: const Icon(Icons.close_rounded),
                                color: AppColors.textMuted,
                                onPressed: () => _remove(w.id, w.name),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
