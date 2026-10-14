# Mobile viewport / first-render layout fix

- Modal size is now measured from child controls *after* theme/font changes, not from arbitrary 505 / 708 height limits.
- Uniform-fit fallback prevents either dialog from overflowing unusually small browser canvas sizes.
- On very short phones, decorative subtitles, descriptions and separators collapse before any essential controls.
- Rules condense from six to four or three sections as the viewport becomes shorter, never scrolls.
- Reflow runs again after the browser has established its final viewport, plus whenever the window changes and each time a menu opens.
- The desktop UI, board interactions and shot mechanics are unchanged.
