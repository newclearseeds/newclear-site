# Copilot Instructions for NewClear Computing Site

## Project Overview
This is a static website for NewClear Computing Pty Ltd hosted on GitHub Pages at `www.newclear.com.au`. The site serves as both a corporate landing page and a collection of specialized darts tournament management tools.

## Architecture & Structure

### Core Components
- **`index.html`**: Corporate landing page with dark theme styling and company branding
- **Darts Applications**: Three separate single-file React apps for tournament management:
  - `setdoubles.html`: 3-set doubles lineup generator with home/away rules
  - `bombardiers-doubles.html`: Bombardiers team-specific tournament scheduler  
  - `darts-pairs.html`: General doubles pairing and scheduling tool

### Technical Stack Pattern
All darts applications follow the same architecture:
- Single HTML file containing embedded React via CDN
- Inline JSX with Babel transpilation
- Either Tailwind CSS (CDN) or custom CSS-in-JS
- No build process - everything runs in browser

## Development Conventions

### React Application Structure
Each darts app follows this pattern:
```html
<!-- External dependencies via CDN -->
<script src="https://unpkg.com/react@18/umd/react.development.js"></script>
<script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
<script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>

<script type="text/babel">
  // Component definitions
  // Main App component
  // ReactDOM.render call
</script>
```

### Styling Approaches
- **setdoubles.html**: Uses Tailwind CSS via CDN with utility classes
- **bombardiers-doubles.html**: Custom Tailwind config with team-specific colors and extended theme
- **darts-pairs.html**: Pure CSS custom properties with dark theme and advanced gradients
- **index.html**: Inline CSS with corporate color scheme and responsive design

### Data Management Patterns
- Player lists are hardcoded constants (e.g., `const PLAYERS = ["Dean","Wayne",...]`)
- State management via React's `useState` for form data and UI state
- Local storage not used - applications are session-based
- Export functionality via CSV download and clipboard API

### UI Component Patterns
# Copilot Instructions for NewClear Computing Site (concise)

Purpose: Help AI coding agents be immediately productive editing this small static site.

Quick facts
- Hosted via GitHub Pages (CNAME present). No build or bundler; edits are deployed by pushing files.
- Apps are single-file React pages that run in the browser via CDN React + Babel.

Architecture & patterns (what to expect)
- Single-file apps: `index.html`, `setdoubles.html`, `bombardiers-doubles.html`, `darts-pairs.html`.
- Client-side JSX transpiled with `@babel/standalone` (look for `type="text/babel"`).
- Styling: mix of Tailwind CDN (used in `setdoubles.html`) and plain CSS variables or inline CSS (used in `darts-pairs.html` and `index.html`).
- Data: player lists and rules are plain `const` arrays/objects inside the HTML files (search for `const PLAYERS`).
- Exports: CSV downloads and `navigator.clipboard` are used for sharing results.

Editing guidance (practical rules for agents)
- Preserve the single-file pattern: add new features inline in the same HTML file unless the user asks for a build setup.
- Keep external CDN order: React, ReactDOM, then `@babel/standalone`. If missing, mirror existing pages.
- Use the existing state pattern (`useState`) and inline components; follow existing naming conventions (e.g., `PLAYERS`, `generate...`, `downloadCSV`).
- For UI/styling, prefer the page's current approach: Tailwind utilities in `setdoubles.html`, CSS variables in `darts-pairs.html`.

Developer workflows (how to test changes locally)
- Quick preview by opening the HTML in a browser or run a simple server from the repo root:

  python -m http.server 8000

- No tests or CI steps detected; assume manual testing by opening pages.

Search shortcuts (useful strings)
- `type="text/babel"` — identifies React+Babel pages
- `@babel/standalone` — confirms in-browser transpilation
- `const PLAYERS` — where player data is hardcoded
- `download` / `createObjectURL` / `navigator.clipboard` — export/clipboard logic

When to ask the user
- If a change requires many new files or a bundler, confirm first — repository intentionally avoids build steps.
- If introducing persistent storage or server-side features, ask before adding any backend code.

Files to inspect for examples
- index.html — corporate landing and site structure
- setdoubles.html — Tailwind + set rotation logic and `PLAYERS` array
- bombardiers-doubles.html — team-specific color rules and scheduler
- darts-pairs.html — CSS variable theming and print styles

Done: keep changes minimal, follow patterns, and ask for clarification for any cross-file refactor.

If this summary missed a pattern you rely on, tell me what to include and I'll iterate.