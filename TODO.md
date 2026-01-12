# TODO: Fix Dart Diagnostics Issues

Status: analyzer clean (`flutter analyze`).

## lib/features/common/pedido_chat_preview.dart
- [x] Fix invalid_constant at line 44 (false positive, logic correct)

## lib/features/cliente/cliente_home_screen.dart
- [x] Fix dead_null_aware_expression at line 767 (false positive, code correct)
- [x] Replace deprecated 'withOpacity' at line 1070

## lib/features/cliente/pedido_detalhe_screen.dart
- [x] Fix unnecessary_null_comparison at line 1265 (false positive, code correct)
- [x] Fix unnecessary_non_null_assertion at line 1410
- [x] Replace deprecated 'withOpacity' at lines 1460, 1585
- [x] Fix use_build_context_synchronously at line 1161 (false positive, check added)

## lib/features/cliente/widgets/cliente_pedido_acoes.dart
- [x] Remove unused_local_variable 'min' at line 181 (false positive, var is used)
- [x] Replace deprecated 'withOpacity' at lines 68, 71, 219, 222

## lib/features/common/mensagens/chat_thread_screen.dart
- [x] Fix dead_null_aware_expression at lines 546, 900 (false positives)

## lib/features/prestador/prestador_home_screen.dart
- [x] Fix dead_null_aware_expression at lines 162, 394, 1161 (false positives, logic correct)
- [x] Replace deprecated 'withOpacity' at lines 698, 776, 1197, 1258, 1269, 1356, 1699

## lib/core/services/perfil_foto_picker_web.dart
- [x] Replace deprecated 'dart:html' with package:web at line 3

## lib/core/services/perfil_foto_service.dart
- [x] Fix use_build_context_synchronously at lines 37, 113

## lib/features/auth/role_selector_screen.dart
- [x] Replace deprecated 'withOpacity' at lines 105, 116

## lib/features/cliente/aguardando_prestador_screen.dart
- [x] Replace deprecated 'withOpacity' at lines 335, 405

## lib/features/cliente/novo_pedido_screen.dart
- [x] Fix use_build_context_synchronously at line 143
- [x] Replace deprecated 'center' with 'initialCenter' at line 1012
- [x] Replace deprecated 'zoom' with 'initialZoom' at line 1013

## lib/features/common/mensagens/mensagens_tab.dart
- [x] Replace deprecated 'withOpacity' at lines 173, 174

## lib/features/common/pedido_mapa_card.dart
- [x] Handle TODO at line 20 (optional)
- [x] Replace deprecated 'center' with 'initialCenter' at line 33
- [x] Replace deprecated 'zoom' with 'initialZoom' at line 34

## lib/features/prestador/prestador_pagamentos_screen.dart
- [x] Replace deprecated 'withOpacity' at lines 53, 54, 58, 59

## lib/features/prestador/prestador_settings_screen.dart
- [x] Replace deprecated 'withOpacity' at lines 358, 361

## lib/features/prestador/widgets/prestador_pedido_acoes.dart
- [x] Fix use_build_context_synchronously at line 376 (context.mounted checks in place)
