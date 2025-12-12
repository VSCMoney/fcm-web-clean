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

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

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

messaging.onBackgroundMessage((payload) => {
  console.log('[SW] Background message:', payload);
  
  const data = payload.data || {};
  const title = data.title || 'Notification';
  const body = data.body || 'You have a message';
  
  return clients.matchAll({ type: 'window', includeUncontrolled: true })
    .then((clientList) => {
      for (let client of clientList) {
        if (client.focused) {
          client.postMessage({ type: 'FCM_MESSAGE', data: data });
          return Promise.resolve();
        }
      }
      
      return self.registration.showNotification(title, {
        body: body,
        icon: '/icons/Icon-192.png',
        data: data,
        tag: data.route || '/',
        requireInteraction: true,
      });
    });
});

self.addEventListener('notificationclick', (event) => {
  console.log('[SW] NOTIFICATION CLICKED');
  event.notification.close();

  const data = event.notification.data || {};
  const route = data.route || '/';
  
  const swURL = new URL(self.location.href);
  const basePath = swURL.pathname.substring(0, swURL.pathname.lastIndexOf('/') + 1);
  const baseURL = swURL.origin + basePath;
  const urlToOpen = baseURL + '#' + route;
  
  console.log('[SW] Opening:', urlToOpen);
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        for (let client of clientList) {
          if (client.url.startsWith(baseURL)) {
            console.log('[SW] Focusing window');
            return client.focus().then(() => {
              client.postMessage({ type: 'NOTIFICATION_CLICK', route: route });
            });
          }
        }
        
        return clients.openWindow ? clients.openWindow(urlToOpen) : null;
      })
  );
});

console.log('✅ FCM Service Worker loaded');
