try {
    const savedTheme = localStorage.getItem('darts_dark_mode');
    const useDark = savedTheme === null
        ? window.matchMedia('(prefers-color-scheme: dark)').matches
        : savedTheme === 'true';
    document.documentElement.classList.toggle('dark', useDark);
} catch {
    // Use the default light theme when storage or media queries are unavailable.
}
