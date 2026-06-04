const HIA_CACHE = "hia-control-tower-shell-v0-1";
const HIA_ASSETS = [
  "./",
  "./index.html",
  "./assets/app.css",
  "./assets/app.js",
  "./manifest.webmanifest"
];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(HIA_CACHE).then((cache) => cache.addAll(HIA_ASSETS)));
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((key) => key !== HIA_CACHE).map((key) => caches.delete(key)))
    )
  );
});

self.addEventListener("fetch", (event) => {
  event.respondWith(caches.match(event.request).then((cached) => cached || fetch(event.request)));
});
