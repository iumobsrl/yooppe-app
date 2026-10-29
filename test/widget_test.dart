import 'package:flutter_test/flutter_test.dart';
import 'package:yooppe/data/profiles.dart';

void main() {
  test('i profili hanno gli stessi dettagli della web app', () {
    final p = profileOf('c1');
    expect(p.u, 'macomesonobella');
    expect(p.d['rel'], 'Separata');
    expect(p.d['alt'], '159 cm');
  });

  test('la Radar con i filtri iniziali (Lazio, 50+, con foto) non è vuota', () {
    final list = radarList(const Filters());
    expect(list, isNotEmpty);
    expect(list.every((p) => p.reg == 'Lazio' && p.age >= 50 && p.hasPh), isTrue);
  });
}
