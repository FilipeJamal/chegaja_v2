import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/catalog/service_taxonomy_matcher.dart';

void main() {
  group('ServiceTaxonomyMatcher', () {
    test('mapeia frases populares para subcategorias canonicas', () {
      expect(
        ServiceTaxonomyMatcher.matchServiceQuery('arranjar luz').bestMatch?.id,
        'electricity',
      );
      expect(
        ServiceTaxonomyMatcher.matchServiceQuery('cano rebentou').bestMatch?.id,
        'plumbing',
      );
      expect(
        ServiceTaxonomyMatcher.matchServiceQuery('bolo aniversário')
            .bestMatch
            ?.id,
        'cakes_confectionery',
      );
      expect(
        ServiceTaxonomyMatcher.matchServiceQuery('pc lento').bestMatch?.id,
        'computer_repair',
      );
      expect(
        ServiceTaxonomyMatcher.matchServiceQuery('senhora limpar casa')
            .bestMatch
            ?.id,
        'home_cleaning',
      );
      expect(
        ServiceTaxonomyMatcher.matchServiceQuery('montar chuveiro')
            .bestMatch
            ?.id,
        'plumbing',
      );
      expect(
        ServiceTaxonomyMatcher.matchServiceQuery('comida fitness')
            .bestMatch
            ?.id,
        'athlete_meals',
      );
      expect(
        ServiceTaxonomyMatcher.matchServiceQuery('buscar criança na escola')
            .bestMatch
            ?.id,
        'child_care',
      );
      expect(
        ServiceTaxonomyMatcher.matchServiceQuery('aulas matemática')
            .bestMatch
            ?.id,
        'school_tutoring',
      );
    });

    test('query vazia retorna none sem sugestao falsa', () {
      final match = ServiceTaxonomyMatcher.matchServiceQuery('   ');

      expect(match.confidence, ServiceTaxonomyMatchConfidence.none);
      expect(match.bestMatch, isNull);
      expect(match.suggestions, isEmpty);
    });

    test('query ambigua devolve sugestoes sem forcar melhor match', () {
      final match = ServiceTaxonomyMatcher.matchServiceQuery('aulas');

      expect(match.confidence, ServiceTaxonomyMatchConfidence.low);
      expect(match.bestMatch, isNull);
      expect(
        match.suggestions.map((s) => s.id),
        containsAll(['school_tutoring', 'languages', 'music_lessons']),
      );
    });

    test('explica como encontrou o melhor match', () {
      final match = ServiceTaxonomyMatcher.matchServiceQuery('arranjar luz');

      expect(match.confidence, ServiceTaxonomyMatchConfidence.high);
      expect(match.matchedBy, ServiceTaxonomyMatchedBy.phrase);
      expect(match.normalizedQuery, 'arranjar luz');
    });
  });
}
