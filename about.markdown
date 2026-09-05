---
layout: main
title: About
permalink: /about/
description: Who writes this site and what it is about.
---
<article class="article-page">
  <div class="page-content">
    <div class="wrap-content">
      <p class="back-link"><a href="{{site.baseurl}}/">&larr; All posts</a></p>
      <header class="header-page">
        <h1 class="page-title">About</h1>
      </header>
      <p>I'm <strong>Marko Milić</strong>, a software developer focusing on security — backend and full-stack work in Node.js and TypeScript, with a soft spot for good design and for explaining things simply.</p>
      <p>This site collects short, practical pieces: how a mechanism works, why it exists, and what to do with it — from Git habits and e-mail plumbing to digital signatures explained with a glass box and two keys.</p>

      <aside class="assistant-cta">
        <div class="assistant-cta-icon" aria-hidden="true">💬</div>
        <div class="assistant-cta-body">
          <h2 class="assistant-cta-title">Ask my AI assistant anything</h2>
          <p>This site has a chat assistant that knows my background, projects and CV. Ask it about my experience, the tech I work with, a specific project, or whether I'd fit a role you're hiring for — it answers in seconds, any time of day.</p>
          <p class="assistant-cta-examples">Try: <span>&ldquo;How many years of Java experience does Marko have?&rdquo;</span> <span>&ldquo;Has he led an engineering team?&rdquo;</span> <span>&ldquo;What's his experience with React and TypeScript?&rdquo;</span></p>
          <button type="button" class="assistant-cta-btn" id="open-assistant">Start chatting &rarr;</button>
          <p class="assistant-cta-hint">Or tap the <strong>💬</strong> button in the bottom-right corner at any time.</p>
        </div>
      </aside>

      <p>Find me on <a href="https://github.com/{{site.social-github}}" rel="noopener" target="_blank">GitHub</a>, <a href="https://www.linkedin.com/in/{{site.social-linkedin}}" rel="noopener" target="_blank">LinkedIn</a> or by <a href="mailto:{{site.social-email}}">e-mail</a>.</p>
    </div>
  </div>
</article>

<script>
  // Wire the "Start chatting" button to the floating assistant launcher (assistant.tesons.dev widget).
  (function () {
    var trigger = document.getElementById('open-assistant');
    if (!trigger) return;
    trigger.addEventListener('click', function () {
      var launcher = document.querySelector('button[aria-label="Chat"]');
      if (launcher) {
        launcher.click();
      } else {
        // Widget not loaded yet — retry briefly, then fall back to the corner bubble.
        var tries = 0;
        var timer = setInterval(function () {
          var b = document.querySelector('button[aria-label="Chat"]');
          if (b || ++tries > 20) {
            clearInterval(timer);
            if (b) b.click();
          }
        }, 150);
      }
    });
  })();
</script>
