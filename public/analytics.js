window.addEventListener('load', () => {
  if (!('sendBeacon' in navigator)) {
    return;
  }
  if (location.hostname !== 'jakobferdinand.at') {
    return;
  }
  let referrerHost = '';
  try {
    referrerHost = new URL(document.referrer).host;
  } catch {
    referrerHost = '';
  }
  const payload = {
    path: location.pathname,
    referrerHost,
    viewportWidth: screen.width,
  };
  const sessionId = readOrCreateId(sessionStorage, 'lt-session');
  if (sessionId) {
    payload.sessionId = sessionId;
  }
  const visitorId = readOrCreateId(localStorage, 'lt-visitor');
  if (visitorId) {
    payload.visitorId = visitorId;
  }
  const entry = performance.getEntriesByType('navigation')[0];
  if (
    entry &&
    (entry.type === 'navigate' || entry.type === 'reload' || entry.type === 'back_forward')
  ) {
    payload.navigationType = entry.type;
  }
  navigator.sendBeacon(
    '/api/pageview',
    new Blob([JSON.stringify(payload)], { type: 'application/json' })
  );
});

function readOrCreateId(storage, key) {
  try {
    let id = storage.getItem(key);
    if (!id) {
      id = crypto.randomUUID();
      storage.setItem(key, id);
    }
    return id;
  } catch {
    return null;
  }
}
