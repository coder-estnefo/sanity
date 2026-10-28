import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/addiction.dart';
import '../bloc/tracker_bloc.dart';

class AddEditPage extends StatefulWidget {
  const AddEditPage({super.key, this.existing});
  final Addiction? existing;

  @override
  State<AddEditPage> createState() => _AddEditPageState();
}

class _AddEditPageState extends State<AddEditPage> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late DateTime _date = widget.existing?.quitDate ?? DateTime.now();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      helpText: 'Date you stopped',
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }
    final existing = widget.existing;
    context.read<TrackerBloc>().add(SaveTracker(Addiction(
          id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          quitDate: _date,
          relapses: existing?.relapses ?? 0,
        )));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'New tracker' : 'Edit tracker')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What are you leaving behind?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.black26),
                borderRadius: BorderRadius.circular(4),
              ),
              leading: const Icon(Icons.event),
              title: const Text('Date you stopped'),
              subtitle: Text(DateFormat.yMMMMd().format(_date)),
              onTap: _pickDate,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}

