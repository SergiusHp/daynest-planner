// Service worker «Мій МЯУдень»: потрібен, щоб Android-браузери могли показати сповіщення-нагадування.
// Сервера push немає, тож сповіщення показує сторінка, поки вона відкрита.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
// тап по сповіщенню: повертаємося у відкрите вікно застосунку або відкриваємо його
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({type: 'window', includeUncontrolled: true}).then(list => {
    for (const c of list) if ('focus' in c) return c.focus();
    return self.clients.openWindow('./');
  }));
});
