let currentSlideIndex = 0;
const slides = document.querySelectorAll('.carousel-slide');
const indicators = document.querySelectorAll('.indicator');
const totalSlides = slides.length;

function showSlide(index) {
    const container = document.getElementById('carouselContainer');
    const translateX = -index * 100;
    container.style.transform = `translateX(${translateX}%)`;

    slides.forEach(slide => slide.classList.remove('active'));
    slides[index].classList.add('active');

    indicators.forEach(indicator => indicator.classList.remove('active'));
    indicators[index].classList.add('active');
}

function changeSlide(direction) {
    currentSlideIndex += direction;
    if (currentSlideIndex >= totalSlides) currentSlideIndex = 0;
    if (currentSlideIndex < 0) currentSlideIndex = totalSlides - 1;
    showSlide(currentSlideIndex);
}

function selectSlide(index) {
    currentSlideIndex = index;
    showSlide(currentSlideIndex);
}

document.querySelector('.carousel-nav.prev').addEventListener('click', () => changeSlide(-1));
document.querySelector('.carousel-nav.next').addEventListener('click', () => changeSlide(1));
indicators.forEach((indicator, index) => {
    indicator.addEventListener('click', () => selectSlide(index));
});

const carousel = document.getElementById('carousel');
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
let autoSlideInterval = 0;

function startAutoSlide() {
    if (reduceMotion) return;
    clearInterval(autoSlideInterval);
    autoSlideInterval = setInterval(() => changeSlide(1), 5000);
}

function stopAutoSlide() {
    clearInterval(autoSlideInterval);
}

startAutoSlide();
carousel.addEventListener('mouseenter', stopAutoSlide);
carousel.addEventListener('mouseleave', startAutoSlide);

document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (event) {
        const target = document.querySelector(this.getAttribute('href'));
        if (!target) return;
        event.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
});

const securityReviewForm = document.getElementById('securityReviewForm');
if (securityReviewForm) {
    securityReviewForm.addEventListener('submit', (event) => {
        const honeypot = securityReviewForm.querySelector('#website');
        if (honeypot && honeypot.value.trim()) {
            event.preventDefault();
        }
    });
}

const siteNav = document.querySelector('.site-nav');
const navToggle = document.querySelector('.nav-toggle');
const primaryNav = document.getElementById('primary-nav');

if (siteNav && navToggle && primaryNav) {
    const desktopNavQuery = window.matchMedia('(min-width: 1181px)');

    const setMenuOpen = (open) => {
        siteNav.classList.toggle('is-open', open);
        navToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
        navToggle.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    };

    navToggle.addEventListener('click', () => {
        setMenuOpen(navToggle.getAttribute('aria-expanded') !== 'true');
    });

    primaryNav.querySelectorAll('a').forEach((link) => {
        link.addEventListener('click', () => setMenuOpen(false));
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') setMenuOpen(false);
    });

    document.addEventListener('click', (event) => {
        if (!siteNav.contains(event.target)) setMenuOpen(false);
    });

    const closeMenuOnDesktop = () => {
        if (desktopNavQuery.matches) setMenuOpen(false);
    };

    if (typeof desktopNavQuery.addEventListener === 'function') {
        desktopNavQuery.addEventListener('change', closeMenuOnDesktop);
    } else if (typeof desktopNavQuery.addListener === 'function') {
        desktopNavQuery.addListener(closeMenuOnDesktop);
    }
}
