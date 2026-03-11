{{flutter_js}}
{{flutter_build_config}}

const isLocalHost =
  window.location.hostname === 'localhost' ||
  window.location.hostname === '127.0.0.1';

_flutter.loader.load({
  serviceWorkerSettings: isLocalHost
    ? null
    : {
        serviceWorkerVersion: {{flutter_service_worker_version}},
      },
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();

    if (typeof window.removeSplashFromWeb === 'function') {
      // Remove splash once Flutter has started. Extra timeout keeps local/dev
      // sessions from getting stuck on splash when startup is slower.
      window.requestAnimationFrame(function () {
        window.removeSplashFromWeb();
      });
      window.setTimeout(function () {
        window.removeSplashFromWeb();
      }, 1500);
    }
  },
});
