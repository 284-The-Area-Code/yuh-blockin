<?php
/**
 * Template Name: YuhBlockin Home
 * Description: Premium landing page for YuhBlockin app
 */

get_header();
?>

<div class="yb-landing">

  <!-- Header -->
  <header class="yb-header">
    <div class="yb-container">
      <div class="yb-header__inner">
        <a href="<?php echo esc_url(home_url('/')); ?>" class="yb-header__logo">
          <img
            src="<?php echo esc_url(get_site_url() . '/wp-content/uploads/2026/01/yuhblockin-logo.png'); ?>"
            alt="YuhBlockin"
            class="yb-header__logo-img"
          >
        </a>

        <nav class="yb-header__nav" aria-label="Main navigation">
          <a href="#how-it-works" class="yb-header__nav-link">How it works</a>
          <a href="#why-it-matters" class="yb-header__nav-link">Why it matters</a>
          <a href="#for-properties" class="yb-header__nav-link">For properties</a>
          <a href="#faq" class="yb-header__nav-link">FAQ</a>
        </nav>

        <a href="#get-app" class="yb-btn yb-btn--primary yb-header__cta">Get YuhBlockin</a>
      </div>
    </div>
  </header>

  <!-- Hero Section -->
  <section class="yb-hero">
    <div class="yb-container">
      <div class="yb-hero__inner">
        <div class="yb-hero__content">
          <h1 class="yb-hero__headline">Don't argue in the lot. Just send a respectful ping.</h1>
          <p class="yb-hero__subcopy">YuhBlockin helps drivers resolve blocked parking quietly and quickly—right from their phones.</p>
          <div class="yb-hero__actions">
            <a href="#get-app" class="yb-btn yb-btn--primary">Get YuhBlockin</a>
            <a href="#how-it-works" class="yb-btn yb-btn--outline">See how it works</a>
          </div>
        </div>

        <div class="yb-hero__visual">
          <img
            src="<?php echo esc_url(get_site_url() . '/wp-content/uploads/2026/01/premium-user-splash.png'); ?>"
            alt="YuhBlockin app interface showing the premium user experience"
            class="yb-hero__image"
          >
        </div>
      </div>
    </div>
  </section>

  <!-- How It Works Section -->
  <section id="how-it-works" class="yb-how">
    <div class="yb-container">
      <header class="yb-section-header">
        <h2 class="yb-section-header__title">How it works</h2>
        <p class="yb-section-header__subtitle">Three simple steps to resolve blocked parking without the drama.</p>
      </header>

      <div class="yb-how__grid">
        <article class="yb-step-card">
          <div class="yb-step-card__icon">
            <svg viewBox="0 0 24 24">
              <rect x="3" y="11" width="18" height="8" rx="2"/>
              <path d="M6 11V6a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v5"/>
              <circle cx="7.5" cy="15.5" r="1.5"/>
              <circle cx="16.5" cy="15.5" r="1.5"/>
            </svg>
          </div>
          <p class="yb-step-card__label">Step 1</p>
          <h3 class="yb-step-card__title">Register your vehicle</h3>
          <p class="yb-step-card__text">Sign up and receive a unique code. Display it on your dashboard so others can reach you.</p>
        </article>

        <article class="yb-step-card">
          <div class="yb-step-card__icon yb-step-card__icon--coral">
            <svg viewBox="0 0 24 24">
              <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
              <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
            </svg>
          </div>
          <p class="yb-step-card__label">Step 2</p>
          <h3 class="yb-step-card__title">Get a respectful alert</h3>
          <p class="yb-step-card__text">When someone's blocked, they enter your code. You get a private, polite notification.</p>
        </article>

        <article class="yb-step-card">
          <div class="yb-step-card__icon yb-step-card__icon--green">
            <svg viewBox="0 0 24 24">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
              <polyline points="22 4 12 14.01 9 11.01"/>
            </svg>
          </div>
          <p class="yb-step-card__label">Step 3</p>
          <h3 class="yb-step-card__title">Move and done</h3>
          <p class="yb-step-card__text">You move your car, they're on their way. No drama, no confrontation, no stress.</p>
        </article>
      </div>
    </div>
  </section>

  <!-- Why It Matters Section -->
  <section id="why-it-matters" class="yb-why">
    <div class="yb-container">
      <header class="yb-section-header">
        <h2 class="yb-section-header__title">Why it matters</h2>
      </header>

      <div class="yb-why__grid">
        <article class="yb-benefit">
          <div class="yb-benefit__dot"></div>
          <h3 class="yb-benefit__title">Less conflict</h3>
          <p class="yb-benefit__text">No honking, no yelling, no awkward confrontations in public spaces.</p>
        </article>

        <article class="yb-benefit">
          <div class="yb-benefit__dot"></div>
          <h3 class="yb-benefit__title">Safer spaces</h3>
          <p class="yb-benefit__text">Remove tension from parking lots. Everyone stays calm and moves on.</p>
        </article>

        <article class="yb-benefit">
          <div class="yb-benefit__dot"></div>
          <h3 class="yb-benefit__title">Respect built in</h3>
          <p class="yb-benefit__text">The system encourages courtesy. Quick, polite communication by design.</p>
        </article>

        <article class="yb-benefit">
          <div class="yb-benefit__dot"></div>
          <h3 class="yb-benefit__title">Faster resolution</h3>
          <p class="yb-benefit__text">Get unblocked in minutes instead of waiting around or hunting someone down.</p>
        </article>
      </div>
    </div>
  </section>

  <!-- For Properties Section -->
  <section id="for-properties" class="yb-properties">
    <div class="yb-container">
      <div class="yb-properties__inner">
        <div class="yb-properties__content">
          <p class="yb-properties__label">For Properties</p>
          <h2 class="yb-properties__title">Give your car parks a better way to communicate</h2>
          <p class="yb-properties__text">Whether you manage a shopping center, office building, or residential complex—YuhBlockin offers a modern alternative to paper notes and PA announcements.</p>
          <ul class="yb-properties__list">
            <li class="yb-properties__list-item">Digital signage templates ready to deploy</li>
            <li class="yb-properties__list-item">QR-based onboarding for visitors</li>
            <li class="yb-properties__list-item">No personal phone numbers posted on walls</li>
          </ul>
          <a href="#contact" class="yb-btn yb-btn--primary">Talk to us about your property</a>
        </div>

        <div class="yb-properties__visual">
          <div class="yb-stat-card">
            <p class="yb-stat-card__number">87%</p>
            <p class="yb-stat-card__label">of blocked situations resolved<br>within 3 minutes</p>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- Product Preview Section -->
  <section class="yb-preview">
    <div class="yb-container">
      <header class="yb-section-header">
        <h2 class="yb-section-header__title">See it in action</h2>
        <p class="yb-section-header__subtitle">Clean, intuitive screens designed for quick resolution.</p>
      </header>

      <div class="yb-preview__grid">
        <div class="yb-preview-device">
          <div class="yb-preview-device__frame">
            <div class="yb-preview-device__screen">
              <p class="yb-preview-device__header">Register</p>
              <div style="background: #21819B; color: #fff; padding: 12px; border-radius: 8px; font-size: 13px; margin-bottom: 12px;">Your Code</div>
              <div class="yb-preview-code">YB-7294</div>
            </div>
          </div>
          <p class="yb-preview-device__label">Register</p>
        </div>

        <div class="yb-preview-device">
          <div class="yb-preview-device__frame">
            <div class="yb-preview-device__screen">
              <p class="yb-preview-device__header">Alert</p>
              <div class="yb-preview-alert">You're blocking someone</div>
              <p class="yb-preview-meta">at Main Street Plaza<br>2 minutes ago</p>
            </div>
          </div>
          <p class="yb-preview-device__label">Alert received</p>
        </div>

        <div class="yb-preview-device">
          <div class="yb-preview-device__frame">
            <div class="yb-preview-device__screen">
              <p class="yb-preview-device__header">Reply</p>
              <div class="yb-preview-reply">On my way now</div>
              <div class="yb-preview-reply">Give me 5 mins</div>
              <div class="yb-preview-reply yb-preview-reply--active">Already moved</div>
            </div>
          </div>
          <p class="yb-preview-device__label">Quick reply</p>
        </div>
      </div>
    </div>
  </section>

  <!-- FAQ Section -->
  <section id="faq" class="yb-faq">
    <div class="yb-container">
      <header class="yb-section-header">
        <h2 class="yb-section-header__title">Common questions</h2>
      </header>

      <div class="yb-faq__list">
        <div class="yb-accordion" data-open="false">
          <button class="yb-accordion__trigger" type="button">
            <span>How does YuhBlockin protect my privacy?</span>
            <span class="yb-accordion__icon">
              <svg viewBox="0 0 24 24"><polyline points="6 9 12 15 18 9"/></svg>
            </span>
          </button>
          <div class="yb-accordion__content" id="faq-1">
            <p class="yb-accordion__text">Your vehicle plate is converted to a secure hash that even we cannot reverse. Notifications are anonymous and one-way. The person alerting you cannot see your personal details, and you cannot see theirs. We collect only what's necessary: a device token for notifications and the hashed identifier.</p>
          </div>
        </div>

        <div class="yb-accordion" data-open="false">
          <button class="yb-accordion__trigger" type="button">
            <span>What notifications will I receive?</span>
            <span class="yb-accordion__icon">
              <svg viewBox="0 0 24 24"><polyline points="6 9 12 15 18 9"/></svg>
            </span>
          </button>
          <div class="yb-accordion__content" id="faq-2">
            <p class="yb-accordion__text">You'll receive a single push notification when someone reports that you're blocking them. That's it. No marketing messages, no reminders, no spam. The app does one thing and does it quietly.</p>
          </div>
        </div>

        <div class="yb-accordion" data-open="false">
          <button class="yb-accordion__trigger" type="button">
            <span>How do I report misuse?</span>
            <span class="yb-accordion__icon">
              <svg viewBox="0 0 24 24"><polyline points="6 9 12 15 18 9"/></svg>
            </span>
          </button>
          <div class="yb-accordion__content" id="faq-3">
            <p class="yb-accordion__text">If you receive false or harassing notifications, you can report them directly in the app. We rate-limit notifications and restrict accounts that show patterns of abuse. The minimal design discourages spam by default.</p>
          </div>
        </div>

        <div class="yb-accordion" data-open="false">
          <button class="yb-accordion__trigger" type="button">
            <span>Where is YuhBlockin available?</span>
            <span class="yb-accordion__icon">
              <svg viewBox="0 0 24 24"><polyline points="6 9 12 15 18 9"/></svg>
            </span>
          </button>
          <div class="yb-accordion__content" id="faq-4">
            <p class="yb-accordion__text">We're starting in the British Virgin Islands via Apple TestFlight. We're adding users gradually as we refine the experience. Android and broader availability will follow based on demand and readiness.</p>
          </div>
        </div>

        <div class="yb-accordion" data-open="false">
          <button class="yb-accordion__trigger" type="button">
            <span>Is there a cost?</span>
            <span class="yb-accordion__icon">
              <svg viewBox="0 0 24 24"><polyline points="6 9 12 15 18 9"/></svg>
            </span>
          </button>
          <div class="yb-accordion__content" id="faq-5">
            <p class="yb-accordion__text">The core service is free during early access. If that changes in the future, we'll communicate clearly and in advance. Our goal is to build useful public infrastructure, not extract value from a captive audience.</p>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- Final CTA Section -->
  <section id="get-app" class="yb-cta">
    <div class="yb-container">
      <h2 class="yb-cta__title">Move with respect.</h2>
      <p class="yb-cta__text">Join the community making parking less stressful in the BVI.</p>
      <a href="#" class="yb-btn yb-btn--primary">Get YuhBlockin</a>
    </div>
  </section>

  <!-- Footer -->
  <footer class="yb-footer">
    <div class="yb-container">
      <div class="yb-footer__grid">
        <div class="yb-footer__column">
          <h4 class="yb-footer__heading">Product</h4>
          <ul class="yb-footer__list">
            <li class="yb-footer__list-item"><a href="#how-it-works" class="yb-footer__link">How it works</a></li>
            <li class="yb-footer__list-item"><a href="#" class="yb-footer__link">Download</a></li>
            <li class="yb-footer__list-item"><a href="#" class="yb-footer__link">For drivers</a></li>
          </ul>
        </div>

        <div class="yb-footer__column">
          <h4 class="yb-footer__heading">For Sites</h4>
          <ul class="yb-footer__list">
            <li class="yb-footer__list-item"><a href="#for-properties" class="yb-footer__link">Property managers</a></li>
            <li class="yb-footer__list-item"><a href="#" class="yb-footer__link">Signage templates</a></li>
            <li class="yb-footer__list-item"><a href="#contact" class="yb-footer__link">Contact sales</a></li>
          </ul>
        </div>

        <div class="yb-footer__column">
          <h4 class="yb-footer__heading">Legal</h4>
          <ul class="yb-footer__list">
            <li class="yb-footer__list-item"><a href="#" class="yb-footer__link">Privacy policy</a></li>
            <li class="yb-footer__list-item"><a href="#" class="yb-footer__link">Terms of service</a></li>
          </ul>
        </div>

        <div class="yb-footer__column">
          <h4 class="yb-footer__heading">Contact</h4>
          <ul class="yb-footer__list">
            <li class="yb-footer__list-item"><a href="mailto:hello@yuhblockin.com" class="yb-footer__link">hello@yuhblockin.com</a></li>
            <li class="yb-footer__list-item"><span class="yb-footer__link">Road Town, Tortola</span></li>
            <li class="yb-footer__list-item"><span class="yb-footer__link">British Virgin Islands</span></li>
          </ul>
        </div>
      </div>

      <div class="yb-footer__bottom">
        <p class="yb-footer__copyright">YuhBlockin. Built for the BVI.</p>
      </div>
    </div>
  </footer>

</div>

<?php get_footer(); ?>
