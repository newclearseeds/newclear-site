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
Reusable components defined inline:
- Badge components with tone-based styling
- Card layouts with consistent header/content structure  
- Button variants (primary, secondary) with hover states
- Form controls with validation feedback

## Key Features & Workflows

### Tournament Rule Implementation
- **Home/Away Rules**: Automatic pair rotation logic in `setdoubles.html`
- **Coverage Validation**: Ensures each set includes players from all Set 1 pairs
- **Duplicate Detection**: Real-time validation preventing player conflicts

### Export & Sharing
All darts apps support multiple output formats:
- Clipboard copy for quick sharing
- CSV export with structured data
- Print-friendly layouts with `@media print` styles

## Development Guidelines

### Adding New Darts Applications
1. Follow the single-file HTML + embedded React pattern
2. Include player validation and conflict detection
3. Implement export functionality (copy, CSV, print)
4. Use consistent UI patterns from existing apps
5. Consider team-specific customization (colors, players, rules)

### Styling Consistency
- Maintain responsive design with mobile-first approach
- Use consistent spacing and border radius patterns
- Implement hover states and micro-interactions
- Consider print styles for tournament documentation

### File Organization
- Keep each application as a single HTML file for easy deployment
- Static assets (`logo.png`, `favicon.ico`) in root directory
- CNAME file configures custom domain for GitHub Pages
- No build artifacts or dependency management needed