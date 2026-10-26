// ==UserScript==
// @name         Color PR owners and repos
// @namespace    https://github.com/barnuri/dev-tools
// @version      1.2.0
// @description  Gives each PR author and each repo a stable color on GitHub pull request lists
// @match        https://github.com/*
// @grant        none
// @updateURL    https://raw.githubusercontent.com/barnuri/dev-tools/master/browser-scripts/color-pr-owners.user.js
// @downloadURL  https://raw.githubusercontent.com/barnuri/dev-tools/master/browser-scripts/color-pr-owners.user.js
// ==/UserScript==

(() => {
  const storageKey = 'color-pr-owners';
  const pullsPage = /^\/(pulls|[^/]+\/[^/]+\/pulls)(\/|$)/;
  const repoPath = /^\/[^/]+\/[^/]+\/?$/;

  const load = () => {
    try {
      return JSON.parse(localStorage.getItem(storageKey)) || {};
    } catch {
      return {};
    }
  };
  const colors = load();

  // Golden-angle hue steps keep consecutive new keys far apart on the color wheel.
  const colorFor = (key) => {
    if (colors[key] === undefined) {
      colors[key] = (Object.keys(colors).length * 137.508) % 360;
      try {
        localStorage.setItem(storageKey, JSON.stringify(colors));
      } catch {}
    }
    return colors[key];
  };

  const isDark = () => {
    const mode = document.documentElement.dataset.colorMode;
    return mode === 'dark' || (mode !== 'light' && matchMedia('(prefers-color-scheme: dark)').matches);
  };

  const paint = (el, key) => {
    if (el.dataset.colorKey === key) {
      return;
    }
    el.dataset.colorKey = key;
    const hue = colorFor(key);
    const text = isDark() ? `hsl(${hue},80%,75%)` : `hsl(${hue},80%,28%)`;
    el.style.cssText += `;background:hsla(${hue},80%,50%,0.18);color:${text} !important;border:1px solid hsla(${hue},80%,50%,0.5);padding:0 6px;border-radius:10px;font-weight:600;text-decoration:none`;
  };

  const authorLogin = (a) => {
    const href = decodeURIComponent(a.getAttribute('href') || '');
    return (href.match(/author:([^\s&+]+)/) || href.match(/^\/([^/?#]+)$/) || [])[1] || a.textContent.trim();
  };

  const isAuthor = (a) =>
    a.dataset.testid === 'author-filter-link' ||
    a.dataset.hovercardType === 'user' ||
    /author(%3A|:)/i.test(a.getAttribute('href') || '');

  // Repo pages, the /pulls dashboard and saved views render rows differently, so a row is any
  // list item that holds a link to a single PR.
  const rows = () =>
    new Set(
      [...document.querySelectorAll('a[href*="/pull/"]')]
        .map((a) => a.closest('li, [role="listitem"], [role="row"], .js-issue-row'))
        .filter(Boolean),
    );

  const repoKey = (a) => {
    const path = new URL(a.href, location.origin).pathname.replace(/\/$/, '');
    const repo = (path.match(/^\/[^/]+\/[^/]+/) || [])[0];
    const text = a.textContent.trim().toLowerCase();
    if (!repo) {
      return null;
    }
    const named = text === repo.slice(1).toLowerCase() || text === repo.split('/')[2].toLowerCase();
    return a.dataset.hovercardType === 'repository' || repoPath.test(path) || named ? `repo:${repo.toLowerCase()}` : null;
  };

  const colorize = () => {
    if (!pullsPage.test(location.pathname)) {
      return;
    }
    for (const row of rows()) {
      for (const a of row.querySelectorAll('a[href]')) {
        if (!a.textContent.trim()) {
          continue;
        }
        if (isAuthor(a)) {
          paint(a, `author:${authorLogin(a).toLowerCase()}`);
          continue;
        }
        const key = repoKey(a);
        if (key) {
          paint(a, key);
        }
      }
    }
  };

  let queued = false;
  new MutationObserver(() => {
    if (!queued) {
      queued = true;
      requestAnimationFrame(() => {
        queued = false;
        colorize();
      });
    }
  }).observe(document.documentElement, { childList: true, subtree: true });
  colorize();
})();
