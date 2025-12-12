// firebase-messaging-sw.js
console.log('🔥 FCM Service Worker loading...');

self.addEventListener('install', (e) => {
  console.log('[SW] Installing...');
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  console.log('[SW] Activating...');
  e.waitUntil(clients.claim());
});

// Firebase compat SDKs
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// 👇 Yahan apna real config daalna (same as Flutter side)
firebase.initializeApp({
 apiKey: 'AIzaSyDI4TXNmJfG8F_jLbCGmTZGgXqVzqBx-qU',
      authDomain: 'vitty-ai.firebaseapp.com',
      projectId: 'vitty-ai',
      storageBucket: 'vitty-ai.firebasestorage.app',
      messagingSenderId: '646509632844',
      appId: '1:646509632844:web:4e12cf4e8e4b89e3be2ee1',
      measurementId: 'G-Y9JYBCBVNJ'
});

const messaging = firebase.messaging();

// 🔔 SIMPLE: har background message pe notification show karo
messaging.onBackgroundMessage((payload) => {
  console.log('[SW] Background message:', payload);

  const data = payload.data || {};
  const title = data.title || 'Notification';
  const body  = data.body  || 'You have a message';

  // IMPORTANT:
  // data.route = "/page1"  (FCM payload me bhejna)
  const route = data.route || '/';

  const notificationOptions = {
    body: body,
    // GitHub Pages pe relative path use karo, na ki leading slash
    icon: 'icons/Icon-192.png',
    data: { route },            // click handler yahi se read karega
    tag: route,
    requireInteraction: true,
  };

  return self.registration.showNotification(title, notificationOptions);
});

// 🖱 CLICK -> existing tab ho to navigate, warna naya tab
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] NOTIFICATION CLICKED');
  event.notification.close();

  const data  = event.notification.data || {};
  let route   = data.route || '/';

  // safety: agar route '#/page1' aajaye
  route = route.replace(/^#/, ''); // remove starting '#'

  // SW ki actual location se base URL calculate karo
  const swURL    = new URL(self.location.href);
  const basePath = swURL.pathname.substring(0, swURL.pathname.lastIndexOf('/') + 1);
  const baseURL  = swURL.origin + basePath;  // e.g. https://vscmoney.github.io/fcm-web-clean/

  const urlToOpen = baseURL + '#' + route;   // -> https://.../fcm-web-clean/#/page1

  console.log('[SW] Opening:', urlToOpen);

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        for (const client of clientList) {
          if (client.url.startsWith(baseURL)) {
            console.log('[SW] Focusing + navigating existing window');
            // navigate karo, sirf postMessage nahi
            if ('navigate' in client) {
              client.focus();
              return client.navigate(urlToOpen);
            } else {
              client.focus();
              return;
            }
          }
        }

        console.log('[SW] Opening new window');
        return clients.openWindow ? clients.openWindow(urlToOpen) : null;
      })
  );
});

console.log('✅ FCM Service Worker loaded');
