import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/logging_service.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('API Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: Consumer<LoggingService>(
        builder: (context, loggingService, child) {
          final logs = loggingService.logs;
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.terminal_rounded,
                    size: 64,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No API activity recorded',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final isError =
                  log.statusCode != null &&
                  (log.statusCode! < 200 || log.statusCode! >= 300);

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: isError
                        ? colorScheme.errorContainer
                        : colorScheme.primaryContainer,
                    child: Text(
                      log.statusCode?.toString() ?? '?',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isError
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(
                    log.method,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    log.timestamp.toString().split('.').first.split(' ').last,
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLogSection('URL', log.url, colorScheme),
                          if (log.requestBody != null)
                            _buildLogSection(
                              'Request Data',
                              log.requestBody!,
                              colorScheme,
                            ),
                          if (log.responseBody != null)
                            _buildLogSection(
                              'Response Data',
                              log.responseBody!,
                              colorScheme,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLogSection(
    String title,
    String content,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          width: double.infinity,
          child: Text(
            content,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs?'),
        content: const Text('This will remove all recorded API activity.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<LoggingService>().clearLogs();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
