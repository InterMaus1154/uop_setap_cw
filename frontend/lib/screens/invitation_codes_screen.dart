import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/invitation_code_provider.dart';
import '../models/invitation_code.dart';

class InvitationCodesScreen extends StatefulWidget {
  const InvitationCodesScreen({super.key});

  @override
  State<InvitationCodesScreen> createState() => _InvitationCodesScreenState();
}

class _InvitationCodesScreenState extends State<InvitationCodesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvitationCodeProvider>().loadCodes();
    });
  }

  Future<void> _handleCreateCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Code'),
        content: const Text(
          'You can create up to 5 codes per week. '
          'Each code expires after 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    await context.read<InvitationCodeProvider>().createNewCode();

    if (!mounted) return;
    final provider = context.read<InvitationCodeProvider>();
    ScaffoldMessenger.of(context).clearSnackBars();
    if (provider.createError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.createError!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation code created successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Invitation Codes'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          if (MediaQuery.of(context).size.width > 600)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton.icon(
                onPressed: _handleCreateCode,
                icon: const Icon(Icons.add),
                label: const Text('New Code'),
              ),
            ),
        ],
      ),
      body: Consumer<InvitationCodeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return _ErrorView(
              message: provider.errorMessage!,
              onRetry: () {
                provider.clearError();
                provider.loadCodes();
              },
            );
          }

          if (provider.codes.isEmpty) {
            return const Center(
              child: Text(
                'No active codes yet.\nTap the + button to generate one and invite a guest.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.codes.length,
            itemBuilder: (context, index) {
              final code = provider.codes[index];
              return _CodeCard(
                code: code,
                onCopy: () => _copyCode(code.code),
              );
            },
          );
        },
      ),
      floatingActionButton: MediaQuery.of(context).size.width <= 600
          ? FloatingActionButton(
              onPressed: _handleCreateCode,
              tooltip: 'Generate new invitation code',
              backgroundColor: Colors.blue[400],
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _CodeCard extends StatelessWidget {
  final InvitationCode code;
  final VoidCallback onCopy;

  const _CodeCard({
    required this.code,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              code.code,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              code.expirationText,
              style: TextStyle(
                color: code.isActive ? Colors.green[600] : Colors.red[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: 'Copy code to clipboard',
                child: TextButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.content_copy),
                  label: const Text('Copy'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry')
          ),
        ],
      ),
    );
  }
}