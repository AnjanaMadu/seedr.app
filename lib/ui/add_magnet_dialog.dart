import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/seedr.dart';

class AddMagnetDialog extends StatefulWidget {
  const AddMagnetDialog({super.key});

  @override
  State<AddMagnetDialog> createState() => _AddMagnetDialogState();
}

class _AddMagnetDialogState extends State<AddMagnetDialog> {
  final _magnetController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addMagnet() async {
    if (_magnetController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final seedr = context.read<Seedr>();
      final result = await seedr.addMagnet(_magnetController.text);
      if (mounted) {
        if (result['result'] == true || result['result'] == 'success') {
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add magnet: ${result['result']}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Magnet Link'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _magnetController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Paste magnet link here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              prefixIcon: const Icon(Icons.link_rounded),
            ),
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _addMagnet,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add Torrent'),
        ),
      ],
    );
  }
}
