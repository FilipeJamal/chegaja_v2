// web/firebase-messaging-sw.js
//
// Firebase Cloud Messaging (FCM) Service Worker.
// Necessário para receber notificações em background no Flutter Web.
//
// Docs:
// - https://firebase.google.com/docs/cloud-messaging/flutter/receive
//
// Nota: usa a versão "compat" do SDK para simplificar.

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAjjapiuGF_hb_Thj6hX5UbvEqOoQ8iYQE',
  authDomain: 'chegaja-ac88d.firebaseapp.com',
  projectId: 'chegaja-ac88d',
  storageBucket: 'chegaja-ac88d.firebasestorage.app',
  messagingSenderId: '767588494857',
  appId: '1:767588494857:web:18d231bee8d6bfe55252d8',
});

const messaging = firebase.messaging();

// Recebe mensagens quando a app está em background/fechada.
// Se vier "notification" no payload, o browser pode mostrar automaticamente.
// Aqui mostramos um notification manual para garantir que o `data` viaja.
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] onBackgroundMessage ', payload);

  const notificationTitle = (payload.notification && payload.notification.title)
    ? payload.notification.title
    : 'ChegaJá';

  const notificationOptions = {
    body: payload.notification && payload.notification.body ? payload.notification.body : '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Clique na notificação: abre a app e, se existir, tenta abrir o pedido.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const data = event.notification.data || {};
  const pedidoId = data.pedidoId;

  const type = (data.type || '').toString();
  const openChat = type === 'chat_message' || type === 'chat' || data.openChat === 'true';

  const urlToOpen = pedidoId
    ? `/?pedidoId=${encodeURIComponent(pedidoId)}${openChat ? '&openChat=true&type=chat' : ''}`
    : '/';

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        // Se já existe um separador aberto, foca.
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.focus();
          // Não conseguimos navegar o Flutter app diretamente; usamos query param.
          return;
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(urlToOpen);
      }
    })
  );
});
