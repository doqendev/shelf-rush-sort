import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/content/product_def.dart';
import 'package:shelf_rush_sort/domain/solver/solver.dart';

void main() {
  test(
    'bundled soft-launch levels pass validation and solver checks',
    () async {
      final ProductCatalog catalog = ProductCatalog.fromJson(
        jsonDecode(
              await File(
                'assets/data/bundled/product_catalog.json',
              ).readAsString(),
            )
            as Map<String, Object?>,
      );
      final LevelPack pack = LevelPack.fromJson(
        jsonDecode(
              await File(
                'assets/data/bundled/level_pack_000.json',
              ).readAsString(),
            )
            as Map<String, Object?>,
      );

      const LevelValidator validator = LevelValidator();
      final report = validator.validatePack(pack, catalog);

      expect(report.issues, isEmpty);
      expect(pack.id, 'pack_000_soft_launch_candidate');
      expect(pack.levels, hasLength(300));
    },
  );
}
