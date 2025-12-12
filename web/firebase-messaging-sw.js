
// firebase-messaging-sw.js
console.log('🔥 FCM Service Worker loading...');

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// ✅ same config as your web FirebaseOptions
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

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));

messaging.onBackgroundMessage((payload) => {
  console.log('[SW] BG message:', payload);
  const data = payload.data || {};
  const title = data.title || 'Notification';
  const body  = data.body  || 'You have a message';
  const route = data.route || '/';

  return self.registration.showNotification(title, {
    body,
    icon: 'icons/Icon-192.png',
    data: { route },
    requireInteraction: true,
    tag: route,
  });
});

self.addEventListener('notificationclick', (event) => {
  console.log('[SW] CLICKED');
  event.notification.close();

  let route = event.notification?.data?.route || '/';
  route = route.replace(/^#/, '');

  // works for GitHub Pages subfolder
  const swURL = new URL(self.location.href);
  const basePath = swURL.pathname.substring(0, swURL.pathname.lastIndexOf('/') + 1);
  const baseURL = swURL.origin + basePath;
  const urlToOpen = baseURL + '#' + route;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      for (const c of list) {
        if (c.url.startsWith(baseURL)) {
          c.focus();
          return c.navigate ? c.navigate(urlToOpen) : undefined;
        }
      }
      return clients.openWindow ? clients.openWindow(urlToOpen) : null;
    })
  );
});

console.log('✅ FCM Service Worker loaded');
