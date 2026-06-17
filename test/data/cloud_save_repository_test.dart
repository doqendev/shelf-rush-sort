import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/infrastructure/save/cloud_save_repository.dart';
import 'package:shelf_rush_sort/infrastructure/save/save_repository.dart';

void main() {
  test('unconfigured cloud save fails closed on load and save', () async {
    const CloudSaveRepository repository = CloudSaveRepository();
    final PlayerSave save = PlayerSave.newPlayer(
      playerId: 'cloud_test',
      startingCoins: 500,
    );

    await expectLater(
      repository.load(),
      throwsA(isA<CloudSaveUnavailableException>()),
    );
    await expectLater(
      repository.save(save),
      throwsA(isA<CloudSaveUnavailableException>()),
    );
  });
}
