import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chegaja_v2/features/common/widgets/media_viewer_screen.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.role,
    this.initialName,
    this.initialPhotoUrl,
  });

  final String userId;
  final String role;
  final String? initialName;
  final String? initialPhotoUrl;

  bool get _isPrestador => role == 'prestador';

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection(_isPrestador ? 'prestadores' : 'users').doc(userId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isPrestador ? l10n.profileProviderTitle : l10n.profileCustomerTitle),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _doc.snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() ?? <String, dynamic>{};

          final name = _resolveName(data, l10n);
          final photo = _resolvePhoto(data);
          final bio = (data['bio'] ?? data['descricao'] ?? '').toString().trim();
          final city = (data['city'] ?? data['cidade'] ?? '').toString().trim();
          final state =
              (data['state'] ?? data['province'] ?? data['region'] ?? '').toString().trim();
          final country = (data['country'] ?? data['pais'] ?? '').toString().trim();
          final phone = _resolvePhone(data);
          final services = _resolveServices(data);
          final portfolio = _resolvePortfolio(data);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(name, photo),
              const SizedBox(height: 16),
              if (bio.isNotEmpty) ...[
                _buildSectionTitle(l10n.profileAboutTitle),
                Text(bio),
                const SizedBox(height: 16),
              ],
              if (city.isNotEmpty || state.isNotEmpty || country.isNotEmpty) ...[
                _buildSectionTitle(l10n.profileLocationTitle),
                Text(
                  [city, state, country].where((e) => e.isNotEmpty).join(', '),
                ),
                const SizedBox(height: 16),
              ],
              if (phone.isNotEmpty) ...[
                _buildSectionTitle('Contacto'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone),
                  title: Text(phone),
                  onTap: () => _openPhone(phone),
                ),
                const SizedBox(height: 16),
              ],
              if (services.isNotEmpty) ...[
                _buildSectionTitle(l10n.profileServicesTitle),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: services
                      .map(
                        (s) => Chip(
                          label: Text(s),
                          backgroundColor: Colors.grey.shade200,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (portfolio.isNotEmpty) ...[
                _buildSectionTitle(l10n.profilePortfolioTitle),
                const SizedBox(height: 8),
                _buildPortfolioGrid(context, portfolio),
              ],
            ],
          );
        },
      ),
    );
  }

  String _resolveName(Map<String, dynamic> data, AppLocalizations l10n) {
    final fromDoc =
        (data['nome'] ?? data['displayName'] ?? data['name'] ?? '').toString().trim();
    if (fromDoc.isNotEmpty) return fromDoc;
    final fromInitial = (initialName ?? '').trim();
    if (fromInitial.isNotEmpty) return fromInitial;
    return _isPrestador ? l10n.roleLabelProvider : l10n.roleLabelCustomer;
  }

  String? _resolvePhoto(Map<String, dynamic> data) {
    final fromDoc =
        (data['photoUrl'] ?? data['fotoUrl'] ?? data['avatarUrl'] ?? '').toString().trim();
    if (fromDoc.startsWith('http')) return fromDoc;
    final fromInitial = (initialPhotoUrl ?? '').trim();
    if (fromInitial.startsWith('http')) return fromInitial;
    return null;
  }

  List<String> _resolveServices(Map<String, dynamic> data) {
    final nomes = data['servicosNomes'] as List?;
    if (nomes != null) {
      return nomes.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return const <String>[];
  }

  List<String> _resolvePortfolio(Map<String, dynamic> data) {
    final urls = data['portfolioUrls'] as List?;
    final images = data['portfolioImages'] as List?;
    final merged = <String>[];
    if (urls != null) merged.addAll(urls.map((e) => e.toString()));
    if (images != null) merged.addAll(images.map((e) => e.toString()));
    return merged.where((e) => e.trim().isNotEmpty).toList();
  }

  String _resolvePhone(Map<String, dynamic> data) {
    final phone = (data['phoneE164'] ?? data['phoneNumber'] ?? data['phone'] ?? '')
        .toString()
        .trim();
    if (phone.isNotEmpty) return phone;
    final raw = (data['phoneRaw'] ?? '').toString().trim();
    return raw;
  }

  Widget _buildHeader(String name, String? photo) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundImage: photo != null ? NetworkImage(photo) : null,
          child: photo == null
              ? Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(fontSize: 24),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPortfolioGrid(BuildContext context, List<String> urls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: urls.length,
      itemBuilder: (context, index) {
        final url = urls[index];
        return GestureDetector(
          onTap: () {
            MediaViewerScreen.open(
              context,
              urls: urls,
              initialIndex: index,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPhone(String phone) async {
    final uri = Uri.tryParse('tel:$phone');
    if (uri == null) return;
    await launchUrl(uri);
  }
}
