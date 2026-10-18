// Service worker de GymTrack.
//
// Objetivo: que la app ABRA aunque en el gym no haya señal. Los datos ya
// funcionan sin conexión gracias a la caché de Firestore; esto cubre los
// archivos de la app (HTML, JS, CanvasKit, fuentes, íconos).
//
// Estrategia:
//  - Archivos de la app: primero red (para recibir actualizaciones). Si ya
//    hay copia guardada y la red no responde en 4 s, se usa la copia.
//    En la primera visita se espera la red sin límite.
//  - Fuentes de Google y CanvasKit (versionados): primero caché.
//  - Firestore, Auth y cualquier otro dominio: no se tocan.
//
// Para forzar que todos descarguen todo de nuevo, cambia CACHE_VERSION.

const CACHE_VERSION = 'v1';
const CACHE = 'gymtrack-' + CACHE_VERSION;
const NETWORK_TIMEOUT_MS = 4000;

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(
      keys.filter((k) => k.startsWith('gymtrack-') && k !== CACHE)
          .map((k) => caches.delete(k)),
    );
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  const sameOrigin = url.origin === self.location.origin;
  const isFont = url.hostname === 'fonts.gstatic.com' ||
                 url.hostname === 'fonts.googleapis.com';
  const isFlutterEngine = url.hostname === 'www.gstatic.com' &&
                          url.pathname.startsWith('/flutter-canvaskit/');

  // Rutas internas de Firebase Hosting / Auth: siempre a la red.
  if (sameOrigin && url.pathname.startsWith('/__/')) return;

  if (isFont || isFlutterEngine) {
    event.respondWith(cacheFirst(req));
  } else if (sameOrigin) {
    event.respondWith(networkFirst(req));
  }
  // Todo lo demás (Firestore, Auth, etc.) pasa directo.
});

async function cacheFirst(req) {
  const cache = await caches.open(CACHE);
  const cached = await cache.match(req);
  if (cached) return cached;
  const res = await fetch(req);
  if (res.ok || res.type === 'opaque') cache.put(req, res.clone());
  return res;
}

async function networkFirst(req) {
  const cache = await caches.open(CACHE);
  // Las navegaciones se guardan como "/" para poder abrir sin conexión.
  const isNav = req.mode === 'navigate';
  const key = isNav ? '/' : req;
  const cached = await cache.match(key, { ignoreSearch: !isNav });

  const network = fetch(req).then((res) => {
    if (res.ok) cache.put(key, res.clone());
    return res;
  });

  // Primera visita (sin copia): esperar la red el tiempo que haga falta.
  if (!cached) return network;

  // Con copia: se espera la red un rato; si tarda o falla, se usa la copia
  // y la descarga sigue en segundo plano para la próxima vez.
  try {
    return await withTimeout(network, NETWORK_TIMEOUT_MS);
  } catch (_) {
    network.catch(() => {});
    return cached;
  }
}

function withTimeout(promise, ms) {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('timeout')), ms);
    promise.then(
      (v) => { clearTimeout(t); resolve(v); },
      (e) => { clearTimeout(t); reject(e); },
    );
  });
}
