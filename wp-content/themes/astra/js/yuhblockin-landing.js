/**
 * YuhBlockin Landing Page Scripts
 * Accessible accordion functionality
 */

(function() {
  'use strict';

  /**
   * Initialize accordion functionality
   */
  function initAccordion() {
    const accordions = document.querySelectorAll('.yb-accordion');

    accordions.forEach(function(accordion) {
      const trigger = accordion.querySelector('.yb-accordion__trigger');
      const content = accordion.querySelector('.yb-accordion__content');
      const contentId = content.id;

      // Set initial ARIA attributes
      trigger.setAttribute('aria-expanded', 'false');
      trigger.setAttribute('aria-controls', contentId);
      content.setAttribute('aria-hidden', 'true');

      // Click handler
      trigger.addEventListener('click', function() {
        toggleAccordion(accordion, trigger, content);
      });

      // Keyboard handler
      trigger.addEventListener('keydown', function(e) {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          toggleAccordion(accordion, trigger, content);
        }
      });
    });
  }

  /**
   * Toggle accordion open/closed
   */
  function toggleAccordion(accordion, trigger, content) {
    const isOpen = accordion.getAttribute('data-open') === 'true';
    const newState = !isOpen;

    accordion.setAttribute('data-open', newState);
    trigger.setAttribute('aria-expanded', newState);
    content.setAttribute('aria-hidden', !newState);
  }

  /**
   * Smooth scroll for anchor links
   */
  function initSmoothScroll() {
    const links = document.querySelectorAll('a[href^="#"]');

    links.forEach(function(link) {
      link.addEventListener('click', function(e) {
        const targetId = this.getAttribute('href');
        if (targetId === '#') return;

        const target = document.querySelector(targetId);
        if (target) {
          e.preventDefault();

          // Check for reduced motion preference
          const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

          target.scrollIntoView({
            behavior: prefersReducedMotion ? 'auto' : 'smooth',
            block: 'start'
          });

          // Update focus for accessibility
          target.setAttribute('tabindex', '-1');
          target.focus({ preventScroll: true });
        }
      });
    });
  }

  /**
   * Initialize on DOM ready
   */
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      initAccordion();
      initSmoothScroll();
    });
  } else {
    initAccordion();
    initSmoothScroll();
  }

})();
