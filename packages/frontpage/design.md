
# Prompt — Build a modern animated frontpage in Flutter (web-first) for Akshara Intelligence

Goal:
Create a modern, lightweight, highly-interactive front page for **Akshara Intelligence** (company profile: interactive 2D geometry + symbolic algebra backend). The page will be implemented in Flutter for the web. Visual design should be clean, academic-techy, and slightly playful — conveying rigor, trust, and discovery. Use subtle motion and micro-interactions to demonstrate the product’s “visual + symbolic” nature without slowing the page.

Audience: educators, students, EdTech integrators, researchers, product/engineering leads.

Deliverables:

1. A single Flutter web page (responsive) with all assets, placeholder components for the interactive geometry demo, and scaffolding for hooking to the backend.
2. Rive/Lottie animation placeholders (or recommend assets) for hero animation and micro-interactions.
3. Example JSON/props for the geometry demo placeholder that visually demonstrates points, lines, a triangle and a short symbolic proof trace animation.
4. README with build/run instructions and list of fonts/assets used.

---

## Overall look & feel

* Visual tone: modern, scholarly, trustworthy. Mix of deep indigo/navy + teal/emerald + warm accent (amber) for CTAs. Plenty of white/neutral space.
* Typography: headings — Poppins or Inter (semi-bold for H1); body — Inter (regular 16px). Use variable fonts where possible.
* Iconography: geometric, minimal SVG line icons (points, line, compass, book, API, cloud, lock).
* Shapes & textures: subtle low-opacity geometric grid or isometric mesh in hero background to hint at geometry.
* Color palette (example):

  * Primary: #0B2340 (deep indigo)
  * Secondary: #0F9D8E (teal)
  * Accent: #FFB239 (warm amber)
  * Neutral: #F7F9FC (off-white), #1F2937 (neutral dark)
* Motion: smooth, performant transitions (use `Curves.easeOutCubic` or `Cubic` easing). Keep animations GPU-friendly.

---

## Page structure & content (ordered top → bottom)

### 1. Meta / Head (SEO & share)

* Title: Akshara Intelligence — Interactive Geometry + Symbolic Algebra
* Meta description: “Explore interactive 2D geometry with a symbolic algebra engine — human-readable proofs, hybrid solvers, and education-grade tools for learning and research.”
* Open Graph image placeholder (SVG snapshot of hero geometry).

### 2. Hero section (full-width, tall)

* Left column (content): headline, 1–2 line deck, 2 CTAs

  * Headline (H1): “Visual Geometry. Symbolic Rigor.”
  * Subhead: “An interactive 2D geometry environment powered by a symbolic algebra core — see constructions, get verifiable step-by-step proofs.”
  * Primary CTA: “Try the Live Demo” (opens interactive demo area / anchor link) — big rounded button using Accent color.
  * Secondary CTA: “Request a Trial / Contact Sales” — outline button.
* Right column (visual demo): framed interactive canvas placeholder (size ~540×360 on desktop) that shows:

  * A small animated geometry scene: draggable points, a triangle highlighted, a dashed circumcircle appearing, and an animated trace showing “Step 1: Define triangle → Step 2: Construct perpendicular bisectors → Step 3: Show circumcenter” — visually animate these steps like a short lesson.
  * Overlaid “View symbolic steps” toggle that flips open a vertically-stacked panel showing short human-readable steps (1–3 lines each) with small math-like notation.
* Hero background: subtle animated grid or parallax lines moving slowly as user scrolls. Use a small Rive or Lottie file for that.

### 3. Key value propositions (3 cards)

* Title: “Why Akshara Intelligence”
* Three horizontally-aligned cards (icon + headline + 1-sentence description):

  1. “Unified Symbolic Core” — “A single algebraic engine that makes proofs verifiable and outputs human-readable reasoning.”
  2. “Interactive Visual Learning” — “Build and explore geometry diagrams with instant symbolic translations.”
  3. “Reliable, Hallucination-Free Results” — “Math-first design guarantees correctness where informal AI fails.”

Each card should have subtle hover lift and micro-anim (shadow + translateY -6px).

### 4. Feature showcase (alternating columns)

* Feature 1: “Interactive Constructions” — show a GIF/animation of constructing a perpendicular and seeing the algebraic relations update live.
* Feature 2: “Automated Proofs & Steps” — show collapsing panels with symbolic steps and small LaTeX-like math.
* Feature 3: “API & SDK” — code snippet box with a short example: `POST /api/solve` showing JSON request & symbolic result payload (mock). Include “Copy” button micro-interaction.
* Feature 4: “Deploy Anywhere” — cloud & on-prem icons; mention security & data privacy.

### 5. Mini interactive playground / live demo anchor

* Full-width section with a larger interactive widget placeholder (or embed an iframe later). Provide a lightweight simulated demo for the landing page:

  * Controls: “Add point”, “Add line”, “Auto-solve” button.
  * When “Auto-solve” clicked, animate the solution steps on the geometry and reveal a right-hand symbolic steps panel that types out step-by-step reasoning (typewriter effect).
* UX: if heavy logic required, the demo should run client-side as a sandboxed simulation (should not call production solver by default). Provide a fallback static animation for non-JS or disabled situations.

### 6. Use cases & industries (grid)

* Short bullets with icons: Education (classrooms & individual learners), Research & R&D, EdTech product integrations, Engineering & Simulation.

### 7. Testimonials / Early adopters

* Short 2–3 testimonials (quote, name, role). If none yet, use “Pilot partners” with logos (placeholder grayscale).

### 8. How it works (3-step flow)

* Step icons + one-liners:

  1. “Construct visually” → 2. “Translate to symbolic representation” → 3. “Get verified solutions & APIs”

### 9. Team / Credibility (small)

* 3–5 avatars + short one-line bios: founder, lead engineer, academic advisor. Link to full team page and papers (future).

### 10. CTA strip

* Full-width, high-contrast CTA: “See the demo — Request early access” (email capture modal). Keep simple form: name, email, organization, use-case (select).

### 11. Footer

* Links: Product, Demo, Docs, Pricing, Privacy, Contact. Copyright + small legal text. Social icons (LinkedIn, GitHub). Minimal sitemap.

---

## Animations & micro-interactions (implementation hints)

* Use `AnimatedContainer`, `AnimatedOpacity`, `SlideTransition`, and `Transform` for lightweight, GPU-friendly animations. Prefer implicit animations for simple transitions.
* Use `Canvas`/`CustomPainter` for the geometry drawing engine placeholder to ensure crisp vector rendering. Keep redraws minimal (only on user interactions).
* Rive/Lottie: use a small looping Rive animation for hero background (subtle motion). Use Lottie for illustrative sequences (e.g., constructing a circle). Provide `prefers-reduced-motion` fallback.
* Typewriter effect for symbolic steps: gradual reveal with `AnimatedDefaultTextStyle` or manual timer-based reveal.
* Parallax: implement only slight parallax offsets for hero grid layers (less than 3% translation) to avoid motion sickness.

---

## Interactive geometry demo technical notes (placeholder)

* Provide a lightweight client-side demo API:

  * Geometry primitives: points, lines, circles, segments, labels.
  * Interactive behaviors: drag points, snap to grid (toggle), show/hide labels.
  * Constraint engine: simple constraint solver (client-side mock) that handles perpendicular, midpoint, distance equality for demo. (Production solver will be server-backed.)
* Symbolic steps panel: each animation step emits a short object `{ stepTitle, latex, explanation }`. The UI should render `latex` using a math renderer (KaTeX or MathJax for web; for Flutter web use `flutter_math_fork` package).
* Example mocked step sequence:

  1. `{title: "Define triangle", latex: "A,B,C", explanation: "Points A, B, C defined."}`
  2. `{title: "Bisectors", latex: "\\text{PerpBis}(AB), \\text{PerpBis}(BC)", explanation: "Construct perpendicular bisectors of AB and BC."}`
  3. `{title: "Circumcenter", latex: "O", explanation: "Intersection of the bisectors is circumcenter O."}`

---

## Accessibility & performance

* Keyboard accessible controls (tab order, focus ring).
* Contrast ratios >= 4.5:1 for body text and >= 3:1 for large text.
* `aria` attributes for interactive controls and role/labels for demo canvas.
* `prefers-reduced-motion` users: disable non-essential animations and replace with simple fades.
* Performance budget: first contentful paint under 1.8s on mid-range connection; avoid huge Lottie/Rive files — keep <200KB when possible. Lazy load heavier assets.

---

## Fonts, libraries & Flutter packages suggestions

* Fonts: Inter / Poppins (host locally or use Google Fonts preload).
* Math rendering: `flutter_math_fork` for LaTeX rendering on Flutter web.
* Animations: `rive` package for Rive files; `lottie` for Lottie.
* UI: standard Flutter widgets plus `animations` package. Optionally use `flutter_hooks` for cleaner state.
* State: `provider` or `riverpod` (lightweight) depending on codebase style.
* Canvas: `CustomPainter` for geometry rendering; consider `GestureDetector`/`Listener` for interactions.

---

## Assets to prepare

* SVG icons for features and geometric primitives.
* Rive/Lottie files: hero background (subtle mesh), demo loop (short 6–8s). If not available, provide design specs so a motion designer can create them.
* Logo: SVG + PNG fallback.
* Mock API response JSON featuring symbolic steps (for dev use).

---

## Copy & microcopy (exact strings you can use)

Hero:

* H1: “Visual Geometry. Symbolic Rigor.”
* Subhead: “Interactive 2D geometry powered by a symbolic algebra core — get verifiable, human-readable solutions.”
  CTAs:
* Primary: “Try the Live Demo”
* Secondary: “Request Early Access”
  Feature headings:
* “Unified Symbolic Core”, “Interactive Visual Learning”, “Hallucination-Free Outputs”
  CTA strip:
* “See how visual intuition becomes verified reasoning. Request early access.”

Form labels:

* “Full name”, “Work email”, “Organization”, “Main use case” (dropdown).

---

## Acceptance criteria (how to know it’s done)

1. Page matches design spec on desktop (>= 1200px), tablet (~768–1024px), and mobile (<= 480px) with content reflow.
2. Hero interactive placeholder runs smoothly (30–60 FPS target), with a working “Auto-solve” demo that animates at least three steps and populates the symbolic panel.
3. CTA form submits to a mock endpoint and shows success/failure states.
4. All critical animations have reduced-motion fallbacks and keyboard-accessible controls.
5. Page loads without major console errors; Lighthouse accessibility score > 90, performance > 50 (acceptable for demo).
6. README includes build/run steps and a list of external assets used.

---

## Extra optional polish (nice-to-have)

* Small animated SVG or CSS math scribbles that transform into clean algebra as you scroll (visual metaphor for “intuition → rigor”).
* Animated onboarding micro-tour (3-step) when first visiting the demo.
* Light/dark theme toggle remembering user preference.

---

## Final note for implementer

Treat the hero demo as a *representative* interactive slice — it should communicate product capability (visual construction + symbolic steps) without requiring the full backend during initial launch. Build clean interfaces and clear data contracts so the production symbolic solver can be integrated later by replacing the mocked demo API.

