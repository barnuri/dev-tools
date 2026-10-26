// ==UserScript==
// @name         Color PR owners and repos
// @namespace    https://github.com/barnuri/dev-tools
// @version      1.0.0
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

  const paint = (el, key) => {
    if (el.dataset.colorKey === key) {
      return;
    }
    el.dataset.colorKey = key;
    const hue = colorFor(key);
    el.style.cssText += `;background:hsl(${hue},65%,40%);color:#fff !important;padding:0 6px;border-radius:10px;text-decoration:none`;
  };

  const authorLogin = (a) => {
    const href = decodeURIComponent(a.getAttribute('href') || '');
    return (href.match(/author:([^\s&+]+)/) || href.match(/^\/([^/?#]+)$/) || [])[1] || a.textContent.trim();
  };

  const rows = () => document.querySelectorAll('[data-listview-component="items-list"] > li, .js-issue-row');

  const colorize = () => {
    if (!pullsPage.test(location.pathname)) {
      return;
    }
    for (const row of rows()) {
      for (const a of row.querySelectorAll('a[data-testid="author-filter-link"], .opened-by a[data-hovercard-type="user"]')) {
        paint(a, `author:${authorLogin(a).toLowerCase()}`);
      }
      for (const a of row.querySelectorAll('a[href]')) {
        const path = new URL(a.href, location.origin).pathname;
        if (a.dataset.testid !== 'author-filter-link' && (a.dataset.hovercardType === 'repository' || repoPath.test(path))) {
          paint(a, `repo:${path.replace(/\/$/, '').toLowerCase()}`);
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
