"""Genera assets/exercise_library.json a partir de free-exercise-db.

Fuente: https://github.com/yuhonas/free-exercise-db (dominio público, Unlicense).

Uso:
    git clone --depth 1 https://github.com/yuhonas/free-exercise-db.git
    python tool/build_exercise_library.py free-exercise-db/dist/exercises.json

Toma los ejercicios de fuerza con equipo de gimnasio, les pone el nombre en
español de tool/exercise_names_es.tsv y traduce músculo y equipo. Los que no
tienen traducción se omiten (agrégalos al .tsv para incluirlos).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

MUSCLES = {
    'quadriceps': 'Piernas', 'hamstrings': 'Femoral', 'glutes': 'Glúteos',
    'abductors': 'Glúteos', 'adductors': 'Aductores', 'calves': 'Pantorrilla',
    'chest': 'Pecho', 'shoulders': 'Hombro', 'lats': 'Espalda',
    'middle back': 'Espalda', 'lower back': 'Espalda baja', 'traps': 'Trapecio',
    'biceps': 'Bíceps', 'triceps': 'Tríceps', 'forearms': 'Antebrazo',
    'abdominals': 'Core', 'neck': 'Cuello',
}
# equipo del dataset -> (etiqueta en español, tipo usado por la app)
EQUIPMENT = {
    'barbell': ('Barra', 'barbell'),
    'e-z curl bar': ('Barra Z', 'barbell'),
    'dumbbell': ('Mancuernas', 'dumbbell'),
    'kettlebells': ('Kettlebell', 'dumbbell'),
    'cable': ('Polea', 'machine'),
    'machine': ('Máquina', 'machine'),
    'body only': ('Peso corporal', 'bodyweight'),
    'bands': ('Banda elástica', 'bodyweight'),
}
CATEGORIES = {'strength', 'powerlifting'}


def main(source):
    names = {}
    with open(os.path.join(HERE, 'exercise_names_es.tsv'), encoding='utf-8') as f:
        for line in f:
            if line.startswith('#') or not line.strip():
                continue
            src_id, name = line.rstrip('\n').split('\t', 1)
            names[src_id] = name

    data = json.load(open(source, encoding='utf-8'))
    out = []
    for x in data:
        if x['category'] not in CATEGORIES or not x['images']:
            continue
        if x.get('equipment') not in EQUIPMENT or x['id'] not in names:
            continue
        label, kind = EQUIPMENT[x['equipment']]
        out.append({
            'id': 'lib_' + x['id'],
            'name': names[x['id']],
            'muscle': MUSCLES.get(x['primaryMuscles'][0], 'Otro'),
            'equipment': label,
            'kind': kind,
            'compound': x.get('mechanic') == 'compound',
            'images': x['images'][:2],
        })
    out.sort(key=lambda e: (e['muscle'], e['name']))
    dest = os.path.join(ROOT, 'assets', 'exercise_library.json')
    with open(dest, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, separators=(',', ':'))
    print(f'{len(out)} ejercicios -> {dest}')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'free-exercise-db/dist/exercises.json')
