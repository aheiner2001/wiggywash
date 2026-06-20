import 'package:flutter/material.dart';

import '../models/worker.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/store_message.dart';

/// Manager screen for adding, editing, and removing employees on the roster.
class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  final _name = TextEditingController();
  final _pin = TextEditingController();
  bool _usePin = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final err = await Store.instance.addWorker(
      _name.text,
      pin: _usePin ? _pin.text : null,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
      showStoreMessage(context, err, error: true);
      return;
    }
    _name.clear();
    _pin.clear();
    setState(() {
      _error = null;
      _usePin = false;
    });
    showStoreMessage(context, 'Added to roster');
  }

  Future<void> _remove(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove worker?'),
        content: Text(
          'Remove $name from the team list? Their past scorecards stay in history.',
        ),
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
    if (ok != true || !mounted) return;

    final err = await Store.instance.removeWorker(id);
    if (!mounted) return;
    if (err != null) {
      showStoreMessage(context, err, error: true);
    } else {
      showStoreMessage(context, '$name removed');
    }
  }

  Future<void> _editWorker(String id, String name, String? currentPin) async {
    final pinController = TextEditingController(text: currentPin ?? '');
    var requirePin = currentPin != null && currentPin.isNotEmpty;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Require entry code'),
                subtitle: const Text('Employee must type this code to sign in'),
                value: requirePin,
                onChanged: (v) => setDialog(() => requirePin = v),
              ),
              if (requirePin) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: pinController,
                  decoration: const InputDecoration(
                    labelText: 'Entry code',
                    hintText: 'e.g. 1234',
                  ),
                  textCapitalization: TextCapitalization.none,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final err = await Store.instance.updateWorker(
      id,
      pin: requirePin ? pinController.text : null,
      clearPin: !requirePin,
    );
    pinController.dispose();

    if (!mounted) return;
    if (err != null) {
      showStoreMessage(context, err, error: true);
    } else {
      showStoreMessage(context, 'Updated $name');
    }
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
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Require entry code'),
                          subtitle: const Text('Optional short code to sign in'),
                          value: _usePin,
                          onChanged: (v) => setState(() => _usePin = v),
                        ),
                        if (_usePin)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller: _pin,
                              decoration: const InputDecoration(
                                labelText: 'Entry code',
                                hintText: 'e.g. 1234',
                              ),
                            ),
                          ),
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
                    _RosterList(
                      workers: workers,
                      onEdit: _editWorker,
                      onRemove: _remove,
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

/// Plain card (no InkWell) so delete/edit buttons receive taps reliably.
class _RosterList extends StatelessWidget {
  const _RosterList({
    required this.workers,
    required this.onEdit,
    required this.onRemove,
  });

  final List<Worker> workers;
  final void Function(String id, String name, String? pin) onEdit;
  final void Function(String id, String name) onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141B2A4A),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('${workers.length} on roster', style: TextStyles.caption),
          ),
          for (final w in workers)
            ListTile(
              onTap: () => onEdit(w.id, w.name, w.pin),
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
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: w.requiresPin
                  ? const Text('Entry code required', style: TextStyles.caption)
                  : null,
              trailing: IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close_rounded),
                color: AppColors.danger,
                onPressed: () => onRemove(w.id, w.name),
              ),
            ),
        ],
      ),
    );
  }
}
