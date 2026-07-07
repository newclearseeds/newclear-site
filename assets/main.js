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

let autoSlideInterval = setInterval(() => changeSlide(1), 5000);
const carousel = document.getElementById('carousel');
carousel.addEventListener('mouseenter', () => clearInterval(autoSlideInterval));
carousel.addEventListener('mouseleave', () => {
    autoSlideInterval = setInterval(() => changeSlide(1), 5000);
});

document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (event) {
        const target = document.querySelector(this.getAttribute('href'));
        if (!target) return;
        event.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
});

document.getElementById('contactForm').addEventListener('submit', function (event) {
    event.preventDefault();
    const name = document.getElementById('name').value.trim();
    const email = document.getElementById('email').value.trim();
    const message = document.getElementById('message').value.trim();

    if (name && email && message) {
        const subject = encodeURIComponent(`Free security review request from ${name}`);
        const body = encodeURIComponent(`Name: ${name}\nEmail: ${email}\n\nSecurity priorities or concerns:\n${message}`);
        window.location.href = `mailto:info@newclear.co?subject=${subject}&body=${body}`;
    } else {
        alert('Please fill in all fields.');
    }
});

const canvas = document.getElementById('matrixCanvas');
const context = canvas.getContext('2d');
const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$@#%&*';
let fontSize = 16;
let columns = [];

function resizeMatrix() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    fontSize = window.innerWidth < 768 ? 14 : 16;
    const columnCount = Math.floor(canvas.width / fontSize);
    columns = Array(columnCount).fill(1);
}

function drawMatrix() {
    context.fillStyle = 'rgba(5, 7, 13, 0.07)';
    context.fillRect(0, 0, canvas.width, canvas.height);
    context.font = `${fontSize}px monospace`;
    context.fillStyle = '#3aa50b';
    for (let index = 0; index < columns.length; index++) {
        const character = letters[Math.floor(Math.random() * letters.length)];
        const x = index * fontSize;
        const y = columns[index] * fontSize;
        context.fillText(character, x, y);
        if (y > canvas.height && Math.random() > 0.975) {
            columns[index] = 0;
        }
        columns[index]++;
    }
}

resizeMatrix();
window.addEventListener('resize', resizeMatrix);
setInterval(drawMatrix, 50);
