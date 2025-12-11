//// firebase-messaging-sw.js - v4.0
//console.log('🔥 Firebase Messaging SW v4.0 loading...');
//
//self.addEventListener('install', (e) => {
//  console.log('[SW v4] Installing...');
//  self.skipWaiting();
//});
//
//self.addEventListener('activate', (e) => {
//  console.log('[SW v4] Activating...');
//  e.waitUntil(clients.claim());
//});
//
//importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
//importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');
//
//firebase.initializeApp({
//  apiKey: 'AIzaSyDI4TXNmJfG8F_jLbCGmTZGgXqVzqBx-qU',
//    authDomain: 'vitty-ai.firebaseapp.com',
//    projectId: 'vitty-ai',
//    storageBucket: 'vitty-ai.firebasestorage.app',
//    messagingSenderId: '646509632844',
//    appId: '1:646509632844:web:4e12cf4e8e4b89e3be2ee1',
//    measurementId: 'G-Y9JYBCBVNJ'
//});
//
//const messaging = firebase.messaging();
//const APP_URL = 'https://vscmoney.github.io/fcm-web-clean/';
//
//console.log('[SW v4] Firebase initialized');
//
//messaging.onBackgroundMessage((payload) => {
//  console.log('[SW v4] ='.repeat(40));
//  console.log('[SW v4] Background message received');
//  console.log('[SW v4] Payload:', JSON.stringify(payload, null, 2));
//
//  // CRITICAL: Extract from data object
//  const data = payload.data || {};
//
//  console.log('[SW v4] Data object:', JSON.stringify(data, null, 2));
//
//  // Extract all fields
//  const title = data.title || payload.notification?.title || 'New Notification';
//  const body = data.body || payload.notification?.body || 'You have a new message';
//  const route = data.route || '/';
//  const imageUrl = data.image_url || '';
//  const icon = data.icon || '/icons/Icon-192.png';
//  const badge = data.badge || '/icons/Icon-192.png';
//  const tag = data.tag || route;
//  const requireInteraction = data.require_interaction !== 'false';
//  const silent = data.silent === 'true';
//
//  // Parse vibration
//  let vibrate = [200, 100, 200];
//  if (data.vibrate) {
//    try {
//      vibrate = JSON.parse(data.vibrate.replace(/'/g, '"'));
//    } catch (e) {
//      console.warn('[SW v4] Invalid vibrate:', data.vibrate);
//    }
//  }
//
//  console.log('[SW v4] Extracted:');
//  console.log('  Title:', title);
//  console.log('  Body:', body);
//  console.log('  Route:', route);
//  console.log('  Image:', imageUrl);
//  console.log('  Icon:', icon);
//  console.log('  Silent:', silent);
//  console.log('  Vibrate:', vibrate);
//
//  return clients.matchAll({ type: 'window', includeUncontrolled: true })
//    .then((clientList) => {
//
//      // Check if app is focused
//      for (let client of clientList) {
//        if (client.focused) {
//          console.log('[SW v4] ⚠️ App focused - forwarding to Flutter');
//          client.postMessage({
//            type: 'FCM_MESSAGE',
//            data: data
//          });
//          return Promise.resolve();
//        }
//      }
//
//      // Show notification
//      console.log('[SW v4] 📢 Showing notification...');
//
//      const notificationOptions = {
//        body: body,
//        icon: icon,
//        badge: badge,
//        data: data,
//        tag: tag,
//        requireInteraction: requireInteraction,
//        silent: silent,
//        vibrate: vibrate,
//        timestamp: Date.now(),
//
//        // Add image if provided
//        ...(imageUrl && { image: imageUrl }),
//
//        // Appearance
//        dir: 'auto',
//        lang: 'en-US',
//      };
//
//      console.log('[SW v4] Notification options:', JSON.stringify(notificationOptions, null, 2));
//
//      return self.registration.showNotification(title, notificationOptions)
//        .then(() => {
//          console.log('[SW v4] ✅ Notification shown successfully');
//        })
//        .catch(err => {
//          console.error('[SW v4] ❌ Error showing notification:', err);
//        });
//    });
//});
//
//self.addEventListener('notificationclick', (event) => {
//  console.log('[SW v4] Notification clicked');
//  event.notification.close();
//
//  const data = event.notification.data || {};
//  const route = data.route || '/';
//  const urlToOpen = APP_URL + '#' + route;
//
//  console.log('[SW v4] Opening:', urlToOpen);
//
//  event.waitUntil(
//    clients.matchAll({ type: 'window', includeUncontrolled: true })
//      .then((clientList) => {
//        for (let client of clientList) {
//          if (client.url.includes('fcm-demo')) {
//            console.log('[SW v4] Focusing existing window');
//            return client.focus().then(() => {
//              client.postMessage({
//                type: 'NOTIFICATION_CLICK',
//                route: route
//              });
//            });
//          }
//        }
//
//        console.log('[SW v4] Opening new window');
//        return clients.openWindow ? clients.openWindow(urlToOpen) : null;
//      })
//  );
//});
//
//console.log('✅ Firebase Messaging SW v4.0 loaded');




// FCM Service Worker - Clean Version
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
  const route = data.route || '/';

  return clients.matchAll({ type: 'window', includeUncontrolled: true })
    .then((clientList) => {
      for (let client of clientList) {
        if (client.focused) {
          console.log('[SW] App focused - forwarding');
          client.postMessage({ type: 'FCM_MESSAGE', data: data });
          return Promise.resolve();
        }
      }

      console.log('[SW] Showing notification');
      return self.registration.showNotification(title, {
        body: body,
        icon: '/icons/Icon-192.png',
        data: data,
        tag: route,
        requireInteraction: true,
      });
    });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
  const route = data.route || '/';

  // Get base URL dynamically
  const swURL = new URL(self.location.href);
  const basePath = swURL.pathname.substring(0, swURL.pathname.lastIndexOf('/') + 1);
  const baseURL = swURL.origin + basePath;
  const urlToOpen = baseURL + '#' + route;

  console.log('[SW] Opening:', urlToOpen);

  event.waitUntil(
    clients.matchAll({ type: 'window' })
      .then((clientList) => {
        for (let client of clientList) {
          if (client.url.startsWith(baseURL)) {
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