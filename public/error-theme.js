// Static errors cannot rely on Rails, Turbo or the Stimulus controller.
(function () {
  var mode;
  try { mode = window.localStorage.getItem('classifieds:theme'); } catch (_) { mode = null; }
  if (mode !== 'light' && mode !== 'dark') {
    mode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
  document.documentElement.setAttribute('data-bs-theme', mode);
}());
