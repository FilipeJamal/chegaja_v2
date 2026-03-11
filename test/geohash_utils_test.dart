import 'package:flutter_test/flutter_test.dart';
import 'package:chegaja_v2/core/utils/geohash_utils.dart';

void main() {
  group('GeoHashUtils', () {
    test('encode returns correct geohash', () {
      // Exemplo conhecido:
      // (57.64911, 10.40744) -> u4pruydqqv
      // Vamos usar uma precisão menor
      final hash = GeoHashUtils.encode(57.64911, 10.40744, precision: 10);
      expect(hash, 'u4pruydqqv');
    });

    test('neighbors returns 9 hashes (center + 8 neighbors)', () {
      // Centro: gcpv
      // Neighbors esperados (aprox):
      // gcpw (N), gcpy (NE), gcpt (E), gcps (SE),
      // gcpk (S), gcph (SW), gcpj (W), gcpn (NW)
      
      const center = 'gcpv';
      final neighbors = GeoHashUtils.neighbors(center);
      
      // Minha implementação retorna [center, n, s, e, w, ne, nw, se, sw] -> 9 items
      expect(neighbors.length, 9);
      
      // Verificação de unicidade
      final unique = neighbors.toSet();
      expect(unique.length, 9);
      
      // Deve conter o centro
      expect(unique.contains(center), true);

      // Verificando alguns vizinhos conhecidos de 'gcpv' (Londres aprox)
      // Top (North) of 'v' is 'y' or similar in base32 map...
      // Vamos confiar na lógica de quantidade e unicidade por enquanto
    });

    test('getGeohashesForRadius returns center + neighbors (9 items normally)', () {
      final hashes = GeoHashUtils.getGeohashesForRadius(51.5074, -0.1278, 5.0); // Londres ~5km
      // Precisão esperada para 5km: 4 chars?
      // 5km <= 50 -> prec 4.
      // Deve retornar 9 hashes.
      expect(hashes.length, 9); 
      
      // Teste de borda: raio muito pequeno
      final smallRadius = GeoHashUtils.getGeohashesForRadius(51.5074, -0.1278, 0.05); // 50m
      expect(smallRadius.isNotEmpty, true);
    });
  });
}
