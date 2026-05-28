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
    this.firestore,
  });

  final String userId;
  final String role;
  final String? initialName;
  final String? initialPhotoUrl;
  final FirebaseFirestore? firestore;

  bool get _isPrestador => role == 'prestador';

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection(_isPrestador ? 'prestadores' : 'users').doc(userId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isPrestador ? l10n.profileProviderTitle : l10n.profileCustomerTitle,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _doc.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return _ProfileErrorState(
                message: 'Nao conseguimos carregar este perfil agora.');
          }

          final profile = _PublicProfileData.fromMap(
            snap.data?.data() ?? <String, dynamic>{},
            isPrestador: _isPrestador,
            initialName: initialName,
            initialPhotoUrl: initialPhotoUrl,
            l10n: l10n,
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              final maxWidth = isDesktop ? 960.0 : 680.0;
              final horizontalPadding =
                  constraints.maxWidth >= 600 ? 24.0 : 16.0;

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      32,
                    ),
                    children: [
                      _ProfileHeader(
                          profile: profile, isPrestador: _isPrestador),
                      const SizedBox(height: 16),
                      if (_isPrestador) ...[
                        _TrustCard(profile: profile),
                        const SizedBox(height: 16),
                      ],
                      _ProfileSection(
                        title: l10n.profileAboutTitle,
                        icon: Icons.person_outline_rounded,
                        child: Text(
                          profile.bio.isNotEmpty
                              ? profile.bio
                              : (_isPrestador
                                  ? 'Este prestador ainda nao adicionou uma descricao.'
                                  : 'Este perfil ainda nao tem descricao.'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ProfileSection(
                        title: 'Area atendida',
                        icon: Icons.location_on_outlined,
                        child: _ServiceArea(profile: profile),
                      ),
                      const SizedBox(height: 16),
                      _ProfileSection(
                        title: l10n.profileServicesTitle,
                        icon: Icons.handyman_outlined,
                        child: _ServicesWrap(services: profile.services),
                      ),
                      const SizedBox(height: 16),
                      _ProfileSection(
                        title: l10n.profilePortfolioTitle,
                        icon: Icons.photo_library_outlined,
                        trailing: profile.portfolio.isNotEmpty
                            ? Text(
                                '${profile.portfolio.length} ${profile.portfolio.length == 1 ? 'imagem' : 'imagens'}',
                                style: Theme.of(context).textTheme.labelMedium,
                              )
                            : null,
                        child: _PortfolioGrid(urls: profile.portfolio),
                      ),
                      if (profile.phone.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _ProfileSection(
                          title: 'Contacto',
                          icon: Icons.phone_outlined,
                          child: _ContactTile(phone: profile.phone),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PublicProfileData {
  const _PublicProfileData({
    required this.name,
    required this.photoUrl,
    required this.bio,
    required this.city,
    required this.state,
    required this.country,
    required this.phone,
    required this.services,
    required this.portfolio,
    required this.radiusKm,
    required this.isPrestador,
  });

  final String name;
  final String? photoUrl;
  final String bio;
  final String city;
  final String state;
  final String country;
  final String phone;
  final List<String> services;
  final List<String> portfolio;
  final double? radiusKm;
  final bool isPrestador;

  factory _PublicProfileData.fromMap(
    Map<String, dynamic> data, {
    required bool isPrestador,
    required String? initialName,
    required String? initialPhotoUrl,
    required AppLocalizations l10n,
  }) {
    final name = _firstNonEmpty([
      data['nome'],
      data['displayName'],
      data['name'],
      initialName,
    ]);

    final photo = _firstValidUrl([
      data['photoUrl'],
      data['fotoUrl'],
      data['avatarUrl'],
      initialPhotoUrl,
    ]);

    final portfolio = _uniqueValidUrls([
      ...?((data['portfolioUrls'] as List?)?.map((e) => e.toString())),
      ...?((data['portfolioImages'] as List?)?.map((e) => e.toString())),
    ]);

    return _PublicProfileData(
      name: name.isNotEmpty
          ? name
          : (isPrestador ? l10n.roleLabelProvider : l10n.roleLabelCustomer),
      photoUrl: photo,
      bio: _firstNonEmpty([data['bio'], data['descricao']]),
      city: _firstNonEmpty([data['city'], data['cidade']]),
      state: _firstNonEmpty([data['state'], data['province'], data['region']]),
      country: _firstNonEmpty([data['country'], data['pais']]),
      phone: _firstNonEmpty([
        data['phoneE164'],
        data['phoneNumber'],
        data['phone'],
        data['phoneRaw'],
      ]),
      services: _stringList(data['servicosNomes']),
      portfolio: portfolio,
      radiusKm: _numToDouble(data['radiusKm']),
      isPrestador: isPrestador,
    );
  }

  String get initial =>
      name.trim().isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : '?';

  bool get hasPhoto => photoUrl != null;

  bool get hasLocation =>
      city.isNotEmpty ||
      state.isNotEmpty ||
      country.isNotEmpty ||
      radiusKm != null;

  bool get hasPortfolio => portfolio.isNotEmpty;

  bool get isActiveProfile =>
      name.trim().isNotEmpty &&
      (bio.isNotEmpty ||
          hasPhoto ||
          services.isNotEmpty ||
          hasLocation ||
          hasPortfolio);

  String get locationLabel {
    final parts = [city, state, country].where((e) => e.trim().isNotEmpty);
    if (parts.isEmpty) return '';
    return 'Atende em ${parts.join(', ')}';
  }

  String get radiusLabel {
    final radius = radiusKm;
    if (radius == null || radius <= 0) return '';
    return 'Raio aproximado: ate ${radius.round()} km';
  }

  List<_TrustBadgeData> get badges {
    final items = <_TrustBadgeData>[];
    if (hasPhoto) {
      items.add(
        const _TrustBadgeData(
          label: 'Foto adicionada',
          icon: Icons.photo_camera_outlined,
        ),
      );
    }
    if (hasLocation) {
      items.add(
        const _TrustBadgeData(
          label: 'Area definida',
          icon: Icons.location_on_outlined,
        ),
      );
    }
    if (hasPortfolio) {
      items.add(
        const _TrustBadgeData(
          label: 'Portfolio adicionado',
          icon: Icons.photo_library_outlined,
        ),
      );
    }
    if (isActiveProfile) {
      items.add(
        const _TrustBadgeData(
          label: 'Perfil ativo',
          icon: Icons.verified_user_outlined,
        ),
      );
    }
    return items;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.isPrestador,
  });

  final _PublicProfileData profile;
  final bool isPrestador;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileAvatar(profile: profile, radius: 42),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPrestador ? 'Prestador' : 'Cliente',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (profile.locationLabel.isNotEmpty)
                  _InlineIconLabel(
                    icon: Icons.location_on_outlined,
                    label: profile.locationLabel,
                  )
                else
                  _InlineIconLabel(
                    icon: Icons.info_outline,
                    label: 'Localizacao ainda nao definida',
                    muted: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard({required this.profile});

  final _PublicProfileData profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final badges = profile.badges;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sinais de confianca',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Informacao factual do perfil, sem verificacao documental.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (badges.isEmpty)
            Text(
              'Este perfil ainda precisa de mais informacao.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.map((badge) => _TrustBadge(badge)).toList(),
            ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge(this.badge);

  final _TrustBadgeData badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(
        badge.icon,
        size: 16,
        color: colorScheme.primary,
      ),
      label: Text(badge.label),
      backgroundColor: colorScheme.primary.withValues(alpha: 0.10),
      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.24)),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _TrustBadgeData {
  const _TrustBadgeData({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ServiceArea extends StatelessWidget {
  const _ServiceArea({required this.profile});

  final _PublicProfileData profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!profile.hasLocation) {
      return Text(
        'Area de atendimento ainda nao definida.',
        style:
            textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.locationLabel.isNotEmpty)
          Text(
            profile.locationLabel,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
        if (profile.radiusLabel.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            profile.radiusLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ServicesWrap extends StatelessWidget {
  const _ServicesWrap({required this.services});

  final List<String> services;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (services.isEmpty) {
      return Text(
        'Servicos ainda nao definidos.',
        style:
            textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: services
          .map(
            (service) => Chip(
              label: Text(service),
              backgroundColor: colorScheme.surfaceContainerHighest,
              side: BorderSide(color: colorScheme.outline),
              labelStyle: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PortfolioGrid extends StatelessWidget {
  const _PortfolioGrid({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (urls.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Ainda sem portfolio',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Quando o prestador adicionar trabalhos, eles aparecem aqui.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 760
            ? 4
            : width >= 520
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: urls.length,
          itemBuilder: (context, index) {
            final url = urls[index];
            return _PortfolioTile(
              url: url,
              onTap: () {
                MediaViewerScreen.open(
                  context,
                  urls: urls,
                  initialIndex: index,
                  title: 'Portfolio',
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({
    required this.url,
    required this.onTap,
  });

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes == null
                      ? null
                      : progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.phone_outlined, color: colorScheme.primary),
      title: Text(phone),
      trailing: const Icon(Icons.open_in_new_rounded),
      onTap: () => _openPhone(phone),
    );
  }

  Future<void> _openPhone(String phone) async {
    final uri = Uri.tryParse('tel:$phone');
    if (uri == null) return;
    await launchUrl(uri);
  }
}

class _InlineIconLabel extends StatelessWidget {
  const _InlineIconLabel({
    required this.icon,
    required this.label,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: muted ? colorScheme.onSurfaceVariant : colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    required this.radius,
  });

  final _PublicProfileData profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
      backgroundImage:
          profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
      onBackgroundImageError: profile.photoUrl != null ? (_, __) {} : null,
      child: profile.photoUrl == null
          ? Text(
              profile.initial,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
            )
          : null,
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: colorScheme.outline),
    boxShadow: [
      BoxShadow(
        color: colorScheme.shadow.withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

String _firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

String? _firstValidUrl(List<Object?> values) {
  for (final value in values) {
    final text = (value ?? '').toString().trim();
    if (_isValidUrl(text)) return text;
  }
  return null;
}

List<String> _stringList(Object? value) {
  final raw = value as List?;
  if (raw == null) return const <String>[];

  final seen = <String>{};
  final result = <String>[];
  for (final item in raw) {
    final text = item.toString().trim();
    if (text.isEmpty || seen.contains(text)) continue;
    seen.add(text);
    result.add(text);
  }
  return result;
}

List<String> _uniqueValidUrls(List<String> urls) {
  final seen = <String>{};
  final result = <String>[];
  for (final url in urls) {
    final text = url.trim();
    if (!_isValidUrl(text) || seen.contains(text)) continue;
    seen.add(text);
    result.add(text);
  }
  return result;
}

bool _isValidUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

double? _numToDouble(Object? value) {
  if (value is num) return value.toDouble();
  return null;
}
