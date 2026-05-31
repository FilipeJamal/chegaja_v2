import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/handles/public_handle_resolver.dart';
import 'package:chegaja_v2/features/common/perfil_publico_screen.dart';

typedef PublicHandleResolveCallback = Future<PublicHandleResolveResult>
    Function(String rawHandle);

class PublicProfileByHandleScreen extends StatefulWidget {
  const PublicProfileByHandleScreen({
    super.key,
    required this.rawHandle,
    this.firestore,
    this.resolveHandle,
  });

  final String rawHandle;
  final FirebaseFirestore? firestore;
  final PublicHandleResolveCallback? resolveHandle;

  @override
  State<PublicProfileByHandleScreen> createState() =>
      _PublicProfileByHandleScreenState();
}

class _PublicProfileByHandleScreenState
    extends State<PublicProfileByHandleScreen> {
  late Future<PublicHandleResolveResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  @override
  void didUpdateWidget(PublicProfileByHandleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawHandle != widget.rawHandle ||
        oldWidget.firestore != widget.firestore ||
        oldWidget.resolveHandle != widget.resolveHandle) {
      _future = _resolve();
    }
  }

  Future<PublicHandleResolveResult> _resolve() async {
    try {
      final resolver = widget.resolveHandle ??
          PublicHandleResolver(firestore: widget.firestore).resolve;
      return await resolver(widget.rawHandle);
    } catch (_) {
      return const PublicHandleResolveResult.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PublicHandleResolveResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PublicHandleStateScaffold(
            title: 'A abrir perfil...',
            showProgress: true,
          );
        }

        final result = snapshot.data;
        if (snapshot.hasError ||
            result == null ||
            result.status == PublicHandleResolveStatus.error) {
          return const _PublicHandleStateScaffold(
            title: 'Nao foi possivel abrir este perfil',
            message: 'Tenta novamente mais tarde.',
          );
        }

        if (result.isResolved && result.uid != null) {
          return PublicProfileScreen(
            userId: result.uid!,
            role: 'prestador',
            initialName: result.handleDisplay,
            firestore: widget.firestore,
          );
        }

        if (result.status == PublicHandleResolveStatus.inactive) {
          return const _PublicHandleStateScaffold(
            title: 'Este perfil nao esta disponivel',
            message:
                'Este link pode estar incorreto ou ja nao estar disponivel.',
          );
        }

        return const _PublicHandleStateScaffold(
          title: 'Perfil nao encontrado',
          message: 'Este link pode estar incorreto ou ja nao estar disponivel.',
        );
      },
    );
  }
}

class _PublicHandleStateScaffold extends StatelessWidget {
  const _PublicHandleStateScaffold({
    required this.title,
    this.message,
    this.showProgress = false,
  });

  final String title;
  final String? message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil publico')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showProgress) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                ] else ...[
                  Icon(
                    Icons.person_search_outlined,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (!showProgress && Navigator.canPop(context)) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Voltar ao inicio'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
