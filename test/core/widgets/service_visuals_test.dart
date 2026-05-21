import 'package:chegaja_v2/core/widgets/service_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('serviceVisualFor', () {
    test('mapeia servicos fixos para assets especificos', () {
      final expected = <String, String>{
        'Canalizador': 'assets/icons/services/service_plumbing.svg',
        'Eletricista': 'assets/icons/services/service_electric.svg',
        'Pintor': 'assets/icons/services/service_painting.svg',
        'Pedreiro': 'assets/icons/services/service_masonry.svg',
        'Serralheiro': 'assets/icons/services/service_locksmith.svg',
        'Carpinteiro': 'assets/icons/services/service_carpentry.svg',
        'Montagem de moveis': 'assets/icons/services/service_assembly.svg',
        'Barbeiro': 'assets/icons/services/service_barber.svg',
        'Cabeleireiro': 'assets/icons/services/service_hairdresser.svg',
        'Babysitter': 'assets/icons/services/service_babysitter.svg',
        'Cuidador de idosos': 'assets/icons/services/service_elder_care.svg',
        'Dog walker': 'assets/icons/services/service_dog_walker.svg',
        'Pet sitter': 'assets/icons/services/service_pet_sitter.svg',
        'Confeitaria': 'assets/icons/services/service_cake.svg',
        'Cake designer': 'assets/icons/services/service_cake.svg',
        'Bolos personalizados': 'assets/icons/services/service_cake.svg',
        'Retratista a lapis': 'assets/icons/services/service_portrait.svg',
        'Caricaturista': 'assets/icons/services/service_caricature.svg',
        'Ilustrador': 'assets/icons/services/service_illustration.svg',
        'Escultor 3D': 'assets/icons/services/service_sculpture_3d.svg',
      };

      for (final entry in expected.entries) {
        expect(
          serviceAssetFor(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('mapeia grupos do catalogo para assets especificos', () {
      final expected = <String, String>{
        'handyman Servicos de reparacao':
            'assets/icons/services/service_handyman.svg',
        'pedreiro Construcao e acabamentos':
            'assets/icons/services/service_masonry.svg',
        'limpeza_domestica Limpeza profissional':
            'assets/icons/services/service_cleaning.svg',
        'mudancas Mudancas e entregas':
            'assets/icons/services/service_moving.svg',
        'mecanico Mecanica auto': 'assets/icons/services/service_mechanic.svg',
        'reparacao_eletrodomesticos Reparacao tecnica':
            'assets/icons/services/service_appliance.svg',
        'web_designer Desenvolvimento digital':
            'assets/icons/services/service_web.svg',
        'designer_grafico Servicos criativos':
            'assets/icons/services/service_graphic_design.svg',
        'cabeleireiro Beleza e estetica':
            'assets/icons/services/service_hairdresser.svg',
        'explicador Explicacoes e formacao':
            'assets/icons/services/service_tutor.svg',
        'massagista Bem-estar e saude':
            'assets/icons/services/service_massage.svg',
        'pet Cuidados para animais':
            'assets/icons/services/service_pet_sitter.svg',
        'catering Eventos': 'assets/icons/services/service_catering.svg',
        'personal_shopper Assistente pessoal':
            'assets/icons/services/service_personal_shopper.svg',
        'artes_marciais Artes marciais':
            'assets/icons/services/service_martial_arts.svg',
        'fitness Fitness e danca': 'assets/icons/services/service_fitness.svg',
        'musica Aulas de musica': 'assets/icons/services/service_music.svg',
        'linguas Aulas de linguas':
            'assets/icons/services/service_language.svg',
        'saude Saude ao domicilio': 'assets/icons/services/service_health.svg',
      };

      for (final entry in expected.entries) {
        expect(
          serviceAssetFor(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('normaliza acentos e mantem fallback seguro', () {
      expect(
        serviceAssetFor('Retratista a lápis'),
        'assets/icons/services/service_portrait.svg',
      );
      expect(serviceIconFor('categoria desconhecida'),
          Icons.home_repair_service_rounded);
      expect(
        serviceAssetFor('categoria desconhecida'),
        'assets/icons/services/service_default.svg',
      );
    });
  });
}
