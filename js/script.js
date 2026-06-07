/**
 * Portfolio Website — Interactive Script
 * Author: AI Agent
 */

(function() {
    'use strict';

    // ============================================
    // DOM Elements
    // ============================================
    const nav = document.getElementById('nav');
    const navToggle = document.getElementById('nav-toggle');
    const navLinks = document.getElementById('nav-links');
    const portfolioGrid = document.getElementById('portfolio-grid');
    const filterBtns = document.querySelectorAll('.filter-btn');
    const lightbox = document.getElementById('lightbox');
    const lightboxImg = document.getElementById('lightbox-img');
    const lightboxClose = document.getElementById('lightbox-close');
    const lightboxPrev = document.getElementById('lightbox-prev');
    const lightboxNext = document.getElementById('lightbox-next');

    // ============================================
    // Navigation
    // ============================================

    // Mobile menu toggle
    navToggle.addEventListener('click', () => {
        navToggle.classList.toggle('active');
        navLinks.classList.toggle('open');
        document.body.style.overflow = navLinks.classList.contains('open') ? 'hidden' : '';
    });

    // Close mobile menu on link click
    navLinks.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', () => {
            navToggle.classList.remove('active');
            navLinks.classList.remove('open');
            document.body.style.overflow = '';
        });
    });

    // Navbar background on scroll
    function handleNavScroll() {
        if (window.scrollY > 50) {
            nav.classList.add('scrolled');
        } else {
            nav.classList.remove('scrolled');
        }
    }

    window.addEventListener('scroll', handleNavScroll, { passive: true });
    handleNavScroll();

    // ============================================
    // Scroll Animations (Intersection Observer)
    // ============================================

    const revealElements = document.querySelectorAll(
        '.section-header, .about-grid, .about-tags, .timeline-item, ' +
        '.portfolio-item, .writing-item, .presentation-card, ' +
        '.skills-layout, .contact-layout'
    );

    const revealObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('reveal', 'visible');
                // Stagger children if they exist
                const children = entry.target.querySelectorAll('.timeline-card, .portfolio-card, .writing-content, .presentation-icon');
                children.forEach((child, i) => {
                    child.style.transitionDelay = `${i * 0.08}s`;
                    child.classList.add('reveal', 'visible');
                });
                revealObserver.unobserve(entry.target);
            }
        });
    }, {
        threshold: 0.15,
        rootMargin: '0px 0px -50px 0px'
    });

    revealElements.forEach(el => {
        el.classList.add('reveal');
        revealObserver.observe(el);
    });

    // ============================================
    // Parallax for decorative elements
    // ============================================

    const parallaxElements = document.querySelectorAll('.hero-accent-circle, .hero-accent-rect, .contact-deco-circle');

    function handleParallax() {
        const scrollY = window.scrollY;
        parallaxElements.forEach((el, index) => {
            const speed = 0.05 + (index * 0.02);
            const yPos = scrollY * speed;
            el.style.transform = `translateY(${yPos}px)`;
        });
    }

    let ticking = false;
    window.addEventListener('scroll', () => {
        if (!ticking) {
            window.requestAnimationFrame(() => {
                handleParallax();
                ticking = false;
            });
            ticking = true;
        }
    }, { passive: true });

    // ============================================
    // Portfolio Filter
    // ============================================

    function applyFilter(filter) {
        const items = portfolioGrid.querySelectorAll('.portfolio-item');
        items.forEach(item => {
            const category = item.dataset.category;
            const show = (filter === 'all' && category === 'all') ||
                         (filter !== 'all' && category === filter);

            if (show) {
                item.classList.remove('hidden');
                item.style.display = '';
            } else {
                item.classList.add('hidden');
                item.style.display = 'none';
            }
        });
    }

    filterBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const filter = btn.dataset.filter;

            // Update active button
            filterBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');

            applyFilter(filter);
        });
    });

    // Auto-apply "all" filter on page load
    applyFilter('all');

    // Reset any stale transforms — all items should be flat now
    document.querySelectorAll('.portfolio-item').forEach(item => {
        item.dataset.originalTransform = '';
    });

    // ============================================
    // Lightbox
    // ============================================

    let currentImageIndex = 0;
    let visibleImages = [];

    function updateVisibleImages() {
        visibleImages = Array.from(document.querySelectorAll('.portfolio-item:not(.hidden) .portfolio-card img'));
    }

    function openLightbox(imgSrc, imgAlt) {
        updateVisibleImages();
        lightboxImg.src = imgSrc;
        lightboxImg.alt = imgAlt;
        lightbox.classList.add('active');
        lightbox.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';

        // Find current index by comparing end of URL path
        // (handles both absolute and relative URLs)
        const srcName = imgSrc.split('/').pop();
        currentImageIndex = visibleImages.findIndex(img => img.src.split('/').pop() === srcName);
    }

    function closeLightbox() {
        lightbox.classList.remove('active');
        lightbox.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
    }

    function showPrevImage() {
        if (visibleImages.length === 0) return;
        currentImageIndex = (currentImageIndex - 1 + visibleImages.length) % visibleImages.length;
        const img = visibleImages[currentImageIndex];
        lightboxImg.src = img.src;
        lightboxImg.alt = img.alt;
    }

    function showNextImage() {
        if (visibleImages.length === 0) return;
        currentImageIndex = (currentImageIndex + 1) % visibleImages.length;
        const img = visibleImages[currentImageIndex];
        lightboxImg.src = img.src;
        lightboxImg.alt = img.alt;
    }

    // Open lightbox on portfolio card click (event delegation)
    portfolioGrid.addEventListener('click', (e) => {
        const card = e.target.closest('.portfolio-card');
        if (!card) return;
        const img = card.querySelector('img');
        if (img && img.src) {
            openLightbox(img.src, img.alt);
        }
    });

    // Lightbox controls
    lightboxClose.addEventListener('click', closeLightbox);
    lightboxPrev.addEventListener('click', showPrevImage);
    lightboxNext.addEventListener('click', showNextImage);

    // Close on background click
    lightbox.addEventListener('click', (e) => {
        if (e.target === lightbox) {
            closeLightbox();
        }
    });

    // Keyboard navigation
    document.addEventListener('keydown', (e) => {
        if (!lightbox.classList.contains('active')) return;

        switch (e.key) {
            case 'Escape':
                closeLightbox();
                break;
            case 'ArrowLeft':
                showPrevImage();
                break;
            case 'ArrowRight':
                showNextImage();
                break;
        }
    });

    // ============================================
    // Skill Bars Animation
    // ============================================

    const skillBars = document.querySelectorAll('.skill-bar-fill');

    const skillObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const bar = entry.target;
                const targetWidth = bar.style.width;
                bar.style.width = '0';
                setTimeout(() => {
                    bar.style.width = targetWidth;
                }, 100);
                skillObserver.unobserve(bar);
            }
        });
    }, { threshold: 0.5 });

    skillBars.forEach(bar => skillObserver.observe(bar));

    // ============================================
    // Smooth scroll for anchor links (fallback)
    // ============================================

    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;

            const target = document.querySelector(targetId);
            if (target) {
                e.preventDefault();
                const navHeight = nav.offsetHeight;
                const targetPosition = target.getBoundingClientRect().top + window.scrollY - navHeight - 20;

                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });

    // ============================================
    // Active nav link on scroll
    // ============================================

    const sections = document.querySelectorAll('section[id]');
    const navLinkEls = document.querySelectorAll('.nav-links a');

    function updateActiveNavLink() {
        const scrollPos = window.scrollY + nav.offsetHeight + 100;

        sections.forEach(section => {
            const top = section.offsetTop;
            const bottom = top + section.offsetHeight;
            const id = section.getAttribute('id');

            if (scrollPos >= top && scrollPos < bottom) {
                navLinkEls.forEach(link => {
                    link.classList.remove('active');
                    if (link.getAttribute('href') === `#${id}`) {
                        link.classList.add('active');
                    }
                });
            }
        });
    }

    window.addEventListener('scroll', () => {
        if (!ticking) {
            window.requestAnimationFrame(() => {
                updateActiveNavLink();
                ticking = false;
            });
            ticking = true;
        }
    }, { passive: true });

    // ============================================
    // Touch swipe for lightbox (mobile)
    // ============================================

    let touchStartX = 0;
    let touchEndX = 0;

    lightbox.addEventListener('touchstart', (e) => {
        touchStartX = e.changedTouches[0].screenX;
    }, { passive: true });

    lightbox.addEventListener('touchend', (e) => {
        touchEndX = e.changedTouches[0].screenX;
        handleSwipe();
    }, { passive: true });

    function handleSwipe() {
        const swipeThreshold = 50;
        const diff = touchStartX - touchEndX;

        if (Math.abs(diff) > swipeThreshold) {
            if (diff > 0) {
                showNextImage();
            } else {
                showPrevImage();
            }
        }
    }

    // ============================================
    // Writing Accordion
    // ============================================

    const writingItems = document.querySelectorAll('.writing-item');

    writingItems.forEach(item => {
        const header = item.querySelector('.writing-header');
        const toggle = item.querySelector('.writing-toggle');

        function toggleItem() {
            const isOpen = item.classList.contains('open');

            // Close all other items
            writingItems.forEach(other => {
                if (other !== item) {
                    other.classList.remove('open');
                    const otherToggle = other.querySelector('.writing-toggle');
                    if (otherToggle) otherToggle.setAttribute('aria-label', 'Раскрыть текст');
                }
            });

            // Toggle current
            item.classList.toggle('open');
            toggle.setAttribute('aria-label', isOpen ? 'Раскрыть текст' : 'Свернуть текст');
        }

        if (header) header.addEventListener('click', toggleItem);
        if (toggle) toggle.addEventListener('click', (e) => { e.stopPropagation(); toggleItem(); });
    });

})();
