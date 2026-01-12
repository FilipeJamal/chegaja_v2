import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/payment_service.dart';

/// Configuração de pagamentos para o prestador (Stripe Connect Express).
///
/// Este ecrã chama Cloud Functions para criar/recuperar a conta Stripe do
/// prestador e abrir o link de onboarding.
class PrestadorPagamentosScreen extends StatelessWidget {
  const PrestadorPagamentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(l10n.invalidSession)),
      );
    }

    final ref = FirebaseFirestore.instance.collection('prestadores').doc(uid);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentsTitle)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() ?? <String, dynamic>{};
          final stripeAccountId = (data['stripeAccountId'] ?? '').toString();
          final onboardingComplete = data['stripeOnboardingComplete'] == true;
          final kycStatus = (data['kycStatus'] ?? 'nao_iniciado').toString();
          final kycDocs = (data['kycDocs'] as List?) ?? <dynamic>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.paymentsHeading,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.paymentsDescription,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: onboardingComplete
                      ? Colors.green.withValues(alpha: 0.06)
                      : Colors.orange.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: onboardingComplete
                        ? Colors.green.withValues(alpha: 0.25)
                        : Colors.orange.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      onboardingComplete ? Icons.check_circle : Icons.info_outline,
                      color: onboardingComplete ? Colors.green[700] : Colors.orange[700],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        onboardingComplete
                            ? l10n.paymentsActive
                            : l10n.paymentsInactive,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              if (stripeAccountId.isNotEmpty)
                Text(
                  l10n.stripeAccountLabel(stripeAccountId),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await PaymentService.instance.startPrestadorOnboarding();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.onboardingOpened),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.onboardingStartError(e.toString())),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  onboardingComplete
                      ? l10n.manageStripeAccount
                      : l10n.activatePayments,
                ),
              ),

              const SizedBox(height: 12),
              _kycSection(
                context,
                prestadorId: uid,
                status: kycStatus,
                docs: kycDocs,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.technicalNotesTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.technicalNotesBody,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kycSection(
    BuildContext context, {
    required String prestadorId,
    required String status,
    required List<dynamic> docs,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final statusLabel = _kycStatusLabel(status, l10n);
    final statusColor = _kycStatusColor(status);
    final canUpload = status != 'aprovado';

    final docNames = <String>[];
    for (final doc in docs) {
      if (doc is Map) {
        final name =
            (doc['name'] ?? doc['fileName'] ?? doc['titulo'] ?? 'documento')
                .toString();
        docNames.add(name);
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.kycTitle(statusLabel),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.kycDescription,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (docNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final name in docNames)
              Text(
                '- $name',
                style: const TextStyle(fontSize: 12),
              ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    canUpload ? () => _pickAndUploadKycDoc(context, prestadorId) : null,
                icon: const Icon(Icons.upload_file),
                label: Text(
                docNames.isEmpty
                    ? l10n.kycSendDocument
                    : l10n.kycAddDocument,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _kycStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'aprovado':
        return l10n.kycStatusApproved;
      case 'rejeitado':
        return l10n.kycStatusRejected;
      case 'em_analise':
        return l10n.kycStatusInReview;
      default:
        return l10n.kycStatusNotStarted;
    }
  }

  Color _kycStatusColor(String status) {
    switch (status) {
      case 'aprovado':
        return Colors.green;
      case 'rejeitado':
        return Colors.red;
      case 'em_analise':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickAndUploadKycDoc(
    BuildContext context,
    String prestadorId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    bool loadingShown = false;

    try {
      final res = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (res == null || res.files.isEmpty) return;

      final file = res.files.first;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.kycFileReadError)),
        );
        return;
      }

      const maxBytes = 10 * 1024 * 1024; // 10MB
      if (bytes.lengthInBytes > maxBytes) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.kycFileTooLarge)),
        );
        return;
      }

      final fileName = _safeFileName(file.name.isNotEmpty ? file.name : 'documento');
      final contentType = _contentTypeForName(fileName);

      if (context.mounted) {
        loadingShown = true;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.kycUploading)),
              ],
            ),
          ),
        );
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('kyc/$prestadorId/${DateTime.now().millisecondsSinceEpoch}_$fileName');

      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      final url = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('prestadores').doc(prestadorId).set(
        {
          'kycStatus': 'em_analise',
          'kycSubmittedAt': FieldValue.serverTimestamp(),
          'kycUpdatedAt': FieldValue.serverTimestamp(),
          'kycDocs': FieldValue.arrayUnion([
            {
              'url': url,
              'name': fileName,
              'contentType': contentType,
              'size': bytes.lengthInBytes,
              'uploadedAt': Timestamp.now(),
            }
          ]),
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.kycUploadSuccess)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.kycUploadError(e.toString()))),
      );
    } finally {
      if (loadingShown && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  String _safeFileName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'documento';
    return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String _contentTypeForName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}
