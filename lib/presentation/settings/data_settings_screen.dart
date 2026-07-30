import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/cloud_sync_repository.dart';
import '../auth/sign_in_screen.dart';
import '../providers/auth_providers.dart';
import '../widgets/pro_gate.dart';
import 'widgets/settings_section.dart';

/// Watch sync + cloud backup. Split out of the Settings hub; the backup actions
/// are Pro-gated and the watch row deep-links to the existing Sync screen.
class DataSettingsScreen extends ConsumerStatefulWidget {
  const DataSettingsScreen({super.key});

  @override
  ConsumerState<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends ConsumerState<DataSettingsScreen> {
  bool _busy = false;

  Future<void> _do(
      Future<CloudSyncResult> Function() action, String okMsg) async {
    if (!await ensurePro(context, ref)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    final msg = switch (result.status) {
      CloudSyncStatus.ok => okMsg,
      CloudSyncStatus.conflict =>
        'Server has newer data — restore first, then back up.',
      CloudSyncStatus.notSignedIn => 'Sign in to use cloud backup.',
      CloudSyncStatus.error => 'Sync failed. Try again.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(isSignedInProvider);
    final repo = ref.read(cloudSyncRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Data & backup')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Space.screenH, Space.md, Space.screenH, Space.screenBottom),
        children: [
          SettingsSection(
            title: 'Watch',
            children: [
              SettingsTile(
                leading: Icons.watch_rounded,
                title: 'Health Connect',
                subtitle: 'Sync runs from your watch',
                onTap: () => context.push('/sync'),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          SettingsSection(
            title: 'Cloud backup',
            children: signedIn
                ? [
                    SettingsTile(
                      leading: Icons.cloud_upload_outlined,
                      title: 'Back up now',
                      subtitle: 'Upload your plan & history',
                      trailing: _busy ? const _MiniSpinner() : null,
                      onTap: _busy
                          ? null
                          : () => _do(repo.push, 'Backed up to the cloud.'),
                    ),
                    SettingsTile(
                      leading: Icons.cloud_download_outlined,
                      title: 'Restore from cloud',
                      subtitle: 'Replace local data with your backup',
                      trailing: _busy ? const _MiniSpinner() : null,
                      onTap: _busy
                          ? null
                          : () => _do(repo.pull, 'Restored from the cloud.'),
                    ),
                  ]
                // A row reading "Sign in from Settings to enable cloud
                // backup", on a Settings page, that you cannot tap. Telling
                // someone where to go is not as good as taking them.
                : [
                    SettingsTile(
                      leading: Icons.login_rounded,
                      title: 'Sign in to back up',
                      subtitle: 'Your plan and history, safe and on every '
                          'device you own',
                      onTap: () => showSignIn(context),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _MiniSpinner extends StatelessWidget {
  const _MiniSpinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
}
