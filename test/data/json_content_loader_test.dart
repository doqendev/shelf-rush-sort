import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/infrastructure/data/json_content_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default content loader uses valid vertical-slice content', () async {
    final service = await JsonContentLoader().load();

    expect(service.content.levelPack.id, 'vertical_slice_pack_000');
    expect(service.content.levelPack.levels, hasLength(15));
  });
}
