import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/catalog/exercise_catalog.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

/// Biblioteca desde assets/exercise_library.json (generado con
/// tool/build_exercise_library.py a partir de free-exercise-db).
///
/// Devuelve primero el catálogo curado (con patrón de movimiento) y después
/// la biblioteca ampliada. Se carga una sola vez y queda en memoria.
class AssetExerciseLibrary implements ExerciseLibraryRepository {
  final AssetBundle bundle;
  final String path;
  List<CatalogExercise>? _cache;

  AssetExerciseLibrary({
    AssetBundle? bundle,
    this.path = 'assets/exercise_library.json',
  }) : bundle = bundle ?? rootBundle;

  @override
  Future<List<CatalogExercise>> getAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final library = <CatalogExercise>[];
    try {
      final raw = jsonDecode(await bundle.loadString(path)) as List;
      for (final item in raw) {
        final m = Map<String, dynamic>.from(item as Map);
        library.add(CatalogExercise(
          Exercise(
            id: m['id'] as String,
            name: m['name'] as String,
            muscleGroup: m['muscle'] as String,
            equipment: m['equipment'] as String,
            imageUrls: [
              for (final p in (m['images'] as List? ?? const []))
                '$kExerciseImageBase$p',
            ],
          ),
          null,
          Equipment.values.asNameMap()[m['kind']] ?? Equipment.machine,
          compound: m['compound'] as bool? ?? false,
        ));
      }
    } catch (_) {
      // Si el archivo falla, al menos queda el catálogo curado.
    }
    return _cache = [...kExerciseCatalog, ...library];
  }
}
