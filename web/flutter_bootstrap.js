{{flutter_js}}
{{flutter_build_config}}

// Arranque personalizado: sin el service worker de Flutter (obsoleto), porque
// usamos el nuestro (gymtrack_sw.js) para que la app abra sin conexión.
_flutter.loader.load();
