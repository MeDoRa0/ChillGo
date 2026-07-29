/* Firebase Messaging service worker. Firebase configuration is injected by
 * the hosting bootstrap before this worker is registered. */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

const config = self.__CHILLGO_FIREBASE_CONFIG__;
if (config) {
  firebase.initializeApp(config);
  firebase.messaging();
}
