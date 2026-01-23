import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/vault_provider.dart';
import '../services/vault_service.dart';

class VaultSelectorScreen extends StatelessWidget {
  const VaultSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultProvider = Provider.of<VaultProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Vault'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.folder,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 24),
              const Text(
                'Geode',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your personal knowledge management system',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),

              if (vaultProvider.vaults.isEmpty) ...[
                const Text(
                  'No vaults found. Create or open a vault to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
              ] else ...[
                const Text(
                  'Recent Vaults',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...vaultProvider.vaults.map((vault) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(vault.name),
                    subtitle: Text(vault.path),
                    trailing: Text(
                      'Last opened: ${_formatDate(vault.lastOpened)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      vaultProvider.setCurrentVault(vault);
                    },
                  ),
                )),
                const SizedBox(height: 32),
              ],

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _createNewVault(context, vaultProvider),
                      icon: const Icon(Icons.create_new_folder),
                      label: const Text('Create New Vault'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openExistingVault(context, vaultProvider),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Open Existing Vault'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _createNewVault(BuildContext context, VaultProvider vaultProvider) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Vault'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Vault Name',
                hintText: 'Enter vault name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'The vault will be created in your Documents folder',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final vaultService = VaultService();
        final defaultPath = await vaultService.getDefaultVaultsDirectory();
        await vaultProvider.createVault(result, defaultPath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vault "$result" created successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating vault: $e')),
          );
        }
      }
    }
  }

  Future<void> _openExistingVault(BuildContext context, VaultProvider vaultProvider) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Vault Directory',
    );

    if (result != null) {
      try {
        await vaultProvider.openVault(result);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vault opened successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening vault: $e')),
          );
        }
      }
    }
  }
}
