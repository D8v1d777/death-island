# Development-build privacy and local data

Death Island's current runtime is offline. The inspected Android manifest requests
VIBRATE (optional haptics) and WAKE_LOCK; it does not request INTERNET, microphone,
camera, contacts, location or shared-storage permission. No analytics, advertising
SDK or automatic crash-upload path was found in the inspected game source.

Game saves and settings are stored locally in app-private storage. Manual
performance export writes a local frame-time CSV; development probes also create
local files. There is no game server receiving this data. Users may independently
choose to share screenshots, logs or reports through GitHub or other applications.

Build/CI tools download development dependencies; that is separate from the shipped
offline runtime. This document describes the inspected development build, not an
approved Google Play Data safety declaration. Public policy hosting, Play Console
forms and review against the final signed artifact remain release gates.
