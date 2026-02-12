'use strict';

// ============================================================================
// Spotify Looper — Custom Service Worker
// Provides: offline fallback, API caching, install lifecycle, background sync
// ============================================================================

const APP_CACHE = 'spotify-looper-app-v1';
const API_CACHE = 'spotify-looper-api-v1';
const OFFLINE_URL = '/offline.html';

// Static assets to pre-cache during install
const PRECACHE_ASSETS = [
    OFFLINE_URL,
    '/icons/Icon-192.png',
    '/icons/Icon-512.png',
    '/favicon.png',
    '/manifest.json',
];

// ── Install ─────────────────────────────────────────────────────────────────
self.addEventListener('install', (event) => {
    console.log('[SW] Installing custom service worker...');
    event.waitUntil(
        caches.open(APP_CACHE).then((cache) => {
            return cache.addAll(PRECACHE_ASSETS);
        })
    );
    // Activate immediately — don't wait for old SW to stop
    self.skipWaiting();
});

// ── Activate ────────────────────────────────────────────────────────────────
self.addEventListener('activate', (event) => {
    console.log('[SW] Activating...');
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames
                    .filter((name) => name !== APP_CACHE && name !== API_CACHE)
                    // Don't delete Flutter's own caches
                    .filter((name) => !name.startsWith('flutter-'))
                    .map((name) => {
                        console.log('[SW] Deleting old cache:', name);
                        return caches.delete(name);
                    })
            );
        })
    );
    // Take control of all clients immediately
    self.clients.claim();
});

// ── Fetch ───────────────────────────────────────────────────────────────────
self.addEventListener('fetch', (event) => {
    const { request } = event;
    const url = new URL(request.url);

    // Only handle GET requests
    if (request.method !== 'GET') return;

    // Strategy 1: Spotify API calls → Network-first with timed cache fallback
    if (url.hostname === 'api.spotify.com') {
        event.respondWith(networkFirstWithTimeout(request, API_CACHE, 5000));
        return;
    }

    // Strategy 2: Spotify CDN (images, album art) → Cache-first, network fallback
    if (
        url.hostname.includes('scdn.co') ||
        url.hostname.includes('spotifycdn.com') ||
        url.hostname.includes('i.scdn.co')
    ) {
        event.respondWith(cacheFirst(request, API_CACHE));
        return;
    }

    // Strategy 3: Navigation requests → Network-first with offline fallback
    if (request.mode === 'navigate') {
        event.respondWith(
            fetch(request).catch(() => {
                return caches.match(OFFLINE_URL);
            })
        );
        return;
    }

    // Strategy 4: Same-origin static assets → handled by Flutter's own SW
    // We don't intercept these to avoid conflicts with flutter_service_worker.js
});

// ── Cache Strategies ────────────────────────────────────────────────────────

/**
 * Network-first with timeout.
 * Tries network; if it takes too long or fails, returns cache.
 */
async function networkFirstWithTimeout(request, cacheName, timeoutMs) {
    const cache = await caches.open(cacheName);

    try {
        const networkPromise = fetch(request);
        const timeoutPromise = new Promise((_, reject) =>
            setTimeout(() => reject(new Error('timeout')), timeoutMs)
        );

        const response = await Promise.race([networkPromise, timeoutPromise]);

        if (response && response.ok) {
            // Clone before caching — responses can only be consumed once
            cache.put(request, response.clone());
        }
        return response;
    } catch (err) {
        const cached = await cache.match(request);
        if (cached) {
            console.log('[SW] Serving from API cache:', request.url);
            return cached;
        }
        // Return a proper error response instead of throwing
        return new Response(
            JSON.stringify({ error: 'offline', message: 'You appear to be offline.' }),
            {
                status: 503,
                statusText: 'Service Unavailable',
                headers: { 'Content-Type': 'application/json' },
            }
        );
    }
}

/**
 * Cache-first, network fallback (good for images / CDN assets).
 */
async function cacheFirst(request, cacheName) {
    const cache = await caches.open(cacheName);
    const cached = await cache.match(request);

    if (cached) return cached;

    try {
        const response = await fetch(request);
        if (response && response.ok) {
            cache.put(request, response.clone());
        }
        return response;
    } catch {
        // For images, return a transparent 1×1 PNG so the UI doesn't break
        return new Response('', { status: 408, statusText: 'Offline' });
    }
}

// ── Messages from the main thread ───────────────────────────────────────────
self.addEventListener('message', (event) => {
    if (event.data === 'skipWaiting') {
        self.skipWaiting();
    }

    if (event.data === 'clearApiCache') {
        caches.delete(API_CACHE).then(() => {
            console.log('[SW] API cache cleared.');
        });
    }
});

// ── Periodic cleanup of stale API cache entries ─────────────────────────────
// Runs once every activation; removes entries older than 1 hour
async function cleanupApiCache() {
    const cache = await caches.open(API_CACHE);
    const keys = await cache.keys();
    const ONE_HOUR = 60 * 60 * 1000;

    for (const request of keys) {
        const response = await cache.match(request);
        if (response) {
            const dateHeader = response.headers.get('date');
            if (dateHeader) {
                const age = Date.now() - new Date(dateHeader).getTime();
                if (age > ONE_HOUR) {
                    await cache.delete(request);
                    console.log('[SW] Evicted stale cache:', request.url);
                }
            }
        }
    }
}

self.addEventListener('activate', (event) => {
    event.waitUntil(cleanupApiCache());
});
