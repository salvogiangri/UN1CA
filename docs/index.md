---
layout: default
title: Home
nav_order: 1
permalink: /
---

<p align="center">
  <img loading="lazy" width="60%" src="/assets/images/logo.png"/>
  <br><br>
  <a href="https://github.com/BlackMesa123/UN1CA"><img loading="lazy" src="https://img.shields.io/badge/GitHub-453f3d?style=for-the-badge&logo=github"/></a>
  <a href="https://t.me/unicarom"><img loading="lazy" src="https://img.shields.io/badge/Telegram-229ed9?style=for-the-badge&logo=telegram&logoColor=ffffff"/></a>
</p>

### - [Supported devices]({% link devices/index.md %})
<br>
#### Thank you to the contributors of UN1CA!

<ul class="list-style-none">
{% for contributor in site.github.contributors %}
  <li class="d-inline-block mr-1">
     <a href="{{ contributor.html_url }}"><img src="{{ contributor.avatar_url }}" width="32" height="32" alt="{{ contributor.login }}"></a>
  </li>
{% endfor %}
</ul>
