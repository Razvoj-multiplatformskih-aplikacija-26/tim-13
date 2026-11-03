import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/serbian.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key, required this.user, this.details = const [], required this.onSignOut});

  final User user;
  final List<(String, String)> details;
  final VoidCallback onSignOut;

  String get _initials => user.name.split(' ').where((part) => part.isNotEmpty).take(2).map((part) => part[0]).join();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: Text(_initials, style: theme.textTheme.headlineSmall?.copyWith(color: scheme.onPrimary)),
              ),
            ),
            const SizedBox(height: 16),
            Text(user.name, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              user.role.label,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: ListTile.divideTiles(
                  context: context,
                  tiles: [
                    for (final (label, value) in [('Uloga', user.role.label), ...details])
                      ListTile(
                        title: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        trailing: Text(value, style: theme.textTheme.titleMedium),
                      ),
                  ],
                ).toList(),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onSignOut,
              style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
              icon: const Icon(Icons.logout),
              label: const Text('Odjavi se'),
            ),
          ],
        ),
      ),
    );
  }
}
