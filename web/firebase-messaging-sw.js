// Firebase Cloud Messaging service worker for web push notifications.
// The firebaseConfig values below are placeholders — replace them with your
// actual Firebase project config from the Firebase Console.

importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBGWIinYblWXKjws0O3J3AuS3sjn26aq1o",
  authDomain: "lipa-cart.firebaseapp.com",
  projectId: "lipa-cart",
  storageBucket: "lipa-cart.firebasestorage.app",
  messagingSenderId: "461833863082",
  appId: "1:461833863082:web:bf946f68ce79646dfbb5d3",
  measurementId: "G-ZM4L9JJ7N5",
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((message) => {
  const notificationTitle = message.notification?.title || "LipaCart";
  const notificationOptions = {
    body: message.notification?.body || "",
    icon: "/favicon.png",
    badge: "/favicon.png",
    data: message.data,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
