// ==UserScript==
// @name         Mark test files as viewed
// @namespace    https://github.com/barnuri/dev-tools
// @version      1.0.0
// @description  Marks every test file in a GitHub PR diff as viewed
// @match        https://github.com/*/pull/*
// @grant        GM_registerMenuCommand
// @updateURL    https://raw.githubusercontent.com/barnuri/dev-tools/master/browser-scripts/mark-test-files-viewed.user.js
// @downloadURL  https://raw.githubusercontent.com/barnuri/dev-tools/master/browser-scripts/mark-test-files-viewed.user.js
// ==/UserScript==

(() => {
  const testFile = /_test|test_|\.test|(^|\/)test\//;
  const testFileKey = /\S*(?:_test|test_|\.test|test\/)\S*/;
  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  const label = (el) => `${el.textContent} ${el.getAttribute('aria-label') || ''} ${el.title || ''}`;

  const viewedButtons = () =>
    [...document.querySelectorAll('button, input[type="checkbox"]')].filter(
      (el) => /viewed/i.test(label(el)) && !/\d+\s*\/\s*\d+/.test(el.textContent),
    );

  const isViewed = (button) =>
    button.checked === true ||
    button.getAttribute('aria-pressed') === 'true' ||
    button.getAttribute('aria-checked') === 'true' ||
    /unmark|unview/i.test(button.getAttribute('aria-label') || '');

  const fileHeader = (button, all) => {
    let el = button;
    let text = '';
    while ((el = el.parentElement) && !el.querySelector('table,[role="grid"]') && all.filter((x) => el.contains(x)).length < 2) {
      text = `${el.innerText} ${[...el.querySelectorAll('[title]')].map((x) => x.title).join(' ')}`;
    }
    return text.replace(/[‎‏]/g, '');
  };

  const findScroller = () => {
    let el = viewedButtons()[0];
    while (el && (el = el.parentElement)) {
      if (/auto|scroll/.test(getComputedStyle(el).overflowY) && el.scrollHeight > el.clientHeight + 10) {
        return el;
      }
    }
    return document.scrollingElement;
  };

  const markTestFilesViewed = async () => {
    const scroller = findScroller();
    const done = new Set();
    let marked = 0;

    const markVisible = async () => {
      for (let i = 0; i < 200; i++) {
        const all = viewedButtons();
        let hit = null;
        for (const button of all) {
          const header = fileHeader(button, all);
          if (isViewed(button) || !testFile.test(header)) {
            continue;
          }
          const key = (header.match(testFileKey) || [header])[0];
          if (done.has(key)) {
            continue;
          }
          hit = [button, key];
          break;
        }
        if (!hit) {
          return;
        }
        done.add(hit[1]);
        console.log('click', hit[1]);
        hit[0].click();
        marked++;
        await sleep(600);
      }
    };

    scroller.scrollTop = 0;
    await sleep(800);
    let last = -1;
    let stuck = 0;
    while (stuck < 3) {
      await markVisible();
      scroller.scrollTop += scroller.clientHeight * 0.8;
      await sleep(700);
      stuck = Math.abs(scroller.scrollTop - last) < 5 ? stuck + 1 : 0;
      last = scroller.scrollTop;
    }
    console.log([...done]);
    alert(`marked ${marked} test files as viewed`);
  };

  if (typeof GM_registerMenuCommand === 'function') {
    GM_registerMenuCommand('Mark test files as viewed', markTestFilesViewed);
  } else {
    markTestFilesViewed();
  }
})();
