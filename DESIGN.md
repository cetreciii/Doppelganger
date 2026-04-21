# Design System — Doppelgänger

---

## 1. Visual Theme & Atmosphere

Doppelgänger is a game for after work, for the train, for chilling with friends. The design should feel like taking off your work shoes — warm, a little wobbly, handmade with joy. It deliberately ignores Apple HIG conventions: no standard navigation bars, no tab bars, no system lists. Every surface is custom. The OS should be invisible; only the game exists.

The design language is built on a foundation of warm cream backgrounds (`#faf9f7`) and oat-toned borders (`#dad4c8`, `#eee9df`) that give every surface a tactile, handmade quality. Against this canvas, a vivid swatch palette provides personality — Matcha green, Slushie cyan, Lemon gold, Ube purple, Pomegranate pink, Blueberry navy, and Dragonfruit magenta.

**Key Characteristics:**
- Warm cream canvas (`#faf9f7`) with oat-toned borders (`#dad4c8`) — artisanal, not clinical
- Named swatch palette: Matcha, Slushie, Lemon, Ube, Pomegranate, Blueberry, Dragonfruit
- Generous border radius: 24px cards, 40px sections, 1584px pills
- Mixed border styles: solid + dashed in the same interface
- Multi-layer shadow with inset highlight: `0px 1px 1px` + `-1px inset` + `-0.5px`
- Spring-based animations everywhere — the UI has mass and bounce, not linear fades
- Cards feel physical — slight resting rotation, hard offset shadows, spring physics on interaction
- Typography at poster scale for key moments — 3 random words displayed big, not as a UI label

---

## 2. Light & Dark Themes

The app supports both light and dark mode. Both share the same swatch palette and playful energy — only the canvas changes.

| Property | Light Mode | Dark Mode |
|---|---|---|
| Canvas (background) | Warm Cream `#faf9f7` | Ube 900 `#32037d` |
| Primary text | Ink `#000000` | Pure White `#ffffff` |
| Secondary text | Warm Silver `#9f9b93` | Ube 300 `#c1b0ff` |
| Primary border | Oat Border `#dad4c8` | Dark Border `#525a69` |
| Card surface | Pure White `#ffffff` | Ube 800 `#43089f` |
| Swatch palette | Unchanged | Unchanged |

**Design intent:** Light mode is a sunny afternoon with friends. Dark mode is the same friends at a house party. Same energy, different hour. The swatch colors remain vivid and unchanged across both — they're the constant personality thread.

---

## 2. Color Palette & Roles

### Primary
- **Ink** (`#000000`): Text, headings
- **Pure White** (`#ffffff`): Card backgrounds, button backgrounds, inverse text
- **Warm Cream** (`#faf9f7`): Page background — the warm, paper-like canvas

### Swatch Palette — Named Colors

**Matcha (Green)**
- **Matcha 300** (`#84e7a5`): Light green accent
- **Matcha 600** (`#078a52`): Mid green
- **Matcha 800** (`#02492a`): Deep green for dark sections

**Slushie (Cyan)**
- **Slushie 500** (`#3bd3fd`): Bright cyan accent
- **Slushie 800** (`#0089ad`): Deep teal

**Lemon (Gold)**
- **Lemon 400** (`#f8cc65`): Warm pale gold
- **Lemon 500** (`#fbbd41`): Primary gold
- **Lemon 700** (`#d08a11`): Deep amber
- **Lemon 800** (`#9d6a09`): Dark amber

**Ube (Purple)**
- **Ube 300** (`#c1b0ff`): Soft lavender
- **Ube 800** (`#43089f`): Deep purple
- **Ube 900** (`#32037d`): Darkest purple

**Pomegranate (Pink/Red)**
- **Pomegranate 400** (`#fc7981`): Warm coral-pink

**Blueberry (Navy Blue)**
- **Blueberry 800** (`#01418d`): Deep navy

### Neutral Scale (Warm)
- **Warm Silver** (`#9f9b93`): Secondary/muted text
- **Warm Charcoal** (`#55534e`): Tertiary text, dark muted links
- **Dark Charcoal** (`#333333`): Link text on light backgrounds

### Surface & Border
- **Oat Border** (`#dad4c8`): Primary border — warm, cream-toned structural lines
- **Oat Light** (`#eee9df`): Secondary lighter border
- **Cool Border** (`#e6e8ec`): Cool-toned border for contrast sections
- **Dark Border** (`#525a69`): Border on dark sections
- **Light Frost** (`#eff1f3`): Subtle button background

### Badges
- **Badge Blue Bg** (`#f0f8ff`): Blue-tinted badge surface
- **Badge Blue Text** (`#3859f9`): Vivid blue badge text
- **Focus Ring** (`rgb(20, 110, 245) solid 2px`): Accessibility focus indicator

### Shadows
- **Layered Shadow** (`rgba(0,0,0,0.1) 0px 1px 1px, rgba(0,0,0,0.04) 0px -1px 1px inset, rgba(0,0,0,0.05) 0px -0.5px 1px`): Multi-layer with inset highlight
- **Hard Offset** (`rgb(0,0,0) -7px 7px`): Hover state — playful hard shadow

---

## 3. Typography Rules

### Font Families
- **Primary**: `Roobert`, fallback: `Arial`
- **Monospace**: `Space Mono`
- **OpenType Features**: `"ss01"`, `"ss03"`, `"ss10"`, `"ss11"`, `"ss12"` on all Roobert text (display uses all 5; body/UI uses `"ss03"`, `"ss10"`, `"ss11"`, `"ss12"`)

### Hierarchy

| Role | Font | Size | Weight | Line Height | Letter Spacing | Notes |
|------|------|------|--------|-------------|----------------|-------|
| Display Hero | Roobert | 80px (5.00rem) | 600 | 1.00 (tight) | -3.2px | All 5 stylistic sets |
| Display Secondary | Roobert | 60px (3.75rem) | 600 | 1.00 (tight) | -2.4px | All 5 stylistic sets |
| Section Heading | Roobert | 44px (2.75rem) | 600 | 1.10 (tight) | -0.88px to -1.32px | All 5 stylistic sets |
| Card Heading | Roobert | 32px (2.00rem) | 600 | 1.10 (tight) | -0.64px | All 5 stylistic sets |
| Feature Title | Roobert | 20px (1.25rem) | 600 | 1.40 | -0.4px | All 5 stylistic sets |
| Sub-heading | Roobert | 20px (1.25rem) | 500 | 1.50 | -0.16px | 4 stylistic sets (no ss01) |
| Body Large | Roobert | 20px (1.25rem) | 400 | 1.40 | normal | 4 stylistic sets |
| Body | Roobert | 18px (1.13rem) | 400 | 1.60 (relaxed) | -0.36px | 4 stylistic sets |
| Body Standard | Roobert | 16px (1.00rem) | 400 | 1.50 | normal | 4 stylistic sets |
| Body Medium | Roobert | 16px (1.00rem) | 500 | 1.20–1.40 | -0.16px to -0.32px | 4–5 stylistic sets |
| Button | Roobert | 16px (1.00rem) | 500 | 1.50 | -0.16px | 4 stylistic sets |
| Button Large | Roobert | 24px (1.50rem) | 400 | 1.50 | normal | 4 stylistic sets |
| Button Small | Roobert | 12.8px (0.80rem) | 500 | 1.50 | -0.128px | 4 stylistic sets |
| Nav Link | Roobert | 15px (0.94rem) | 500 | 1.60 (relaxed) | normal | 4 stylistic sets |
| Caption | Roobert | 14px (0.88rem) | 400 | 1.50–1.60 | -0.14px | 4 stylistic sets |
| Small | Roobert | 12px (0.75rem) | 400 | 1.50 | normal | 4 stylistic sets |
| Uppercase Label | Roobert | 12px (0.75rem) | 600 | 1.20 (tight) | 1.08px | `text-transform: uppercase`, 4 sets |
| Badge | Roobert | 9.6px | 600 | — | — | Pill badges |

### Principles
- **Five stylistic sets as identity**: The combination of `"ss01"`, `"ss03"`, `"ss10"`, `"ss11"`, `"ss12"` on Roobert creates a distinctive typographic personality. `ss01` is reserved for headings and emphasis — body text omits it.
- **Aggressive display compression**: -3.2px at 80px, -2.4px at 60px — compressed display tracking contrasts with generous body spacing (1.60 line-height).
- **Weight 600 for headings, 500 for UI, 400 for body**: Clean three-tier system where each weight has a strict role.
- **Uppercase labels with positive tracking**: 12px uppercase at 1.08px letter-spacing for systematic wayfinding.

---

## 4. Component Stylings

### Buttons

**Primary (Transparent with Hover Animation)**
- Background: transparent (`rgba(239, 241, 243, 0)`)
- Text: `#000000`
- Padding: 6.4px 12.8px
- Border: none (or `1px solid #717989` for outlined variant)
- Hover: background shifts to swatch color (e.g., `#434346`), text to white, `rotateZ(-8deg)`, `translateY(-80%)`, hard shadow `rgb(0,0,0) -7px 7px`
- Focus: `rgb(20, 110, 245) solid 2px` outline

**White Solid**
- Background: `#ffffff`
- Text: `#000000`
- Padding: 6.4px
- Hover: oat swatch color, animated rotation + shadow
- Use: Primary CTA on colored sections

**Ghost Outlined**
- Background: transparent
- Text: `#000000`
- Padding: 8px
- Border: `1px solid #717989`
- Radius: 4px
- Hover: Dragonfruit swatch color, white text, animated rotation

### Cards & Containers
- Background: `#ffffff` on cream canvas
- Border: `1px solid #dad4c8` (warm oat) or `1px dashed #dad4c8`
- Radius: 12px (standard cards), 24px (feature cards/images), 40px (section containers)
- Shadow: `rgba(0,0,0,0.1) 0px 1px 1px, rgba(0,0,0,0.04) 0px -1px 1px inset, rgba(0,0,0,0.05) 0px -0.5px 1px`
- Colorful section backgrounds using swatch palette (Matcha, Slushie, Ube, Lemon)

### Inputs & Forms
- Text: `#000000`
- Border: `1px solid #717989`
- Radius: 4px
- Focus: `rgb(20, 110, 245) solid 2px` outline

### Distinctive Components

**Swatch Color Sections**
- Full-width sections with swatch-colored backgrounds (Matcha green, Slushie cyan, Ube purple, Lemon gold)
- White text on dark swatches, black text on light swatches

**Playful Hover Buttons**
- Rotate -8deg + translate upward on hover
- Hard offset shadow (`-7px 7px`) instead of soft blur
- Background transitions to contrasting swatch color

**Dashed Border Elements**
- `1px dashed #dad4c8` alongside solid borders
- Used for secondary containers and decorative elements

---

## 5. Layout Principles

### Spacing System
- Base unit: 8px
- Scale: 1px, 2px, 4px, 6.4px, 8px, 12px, 12.8px, 16px, 18px, 20px, 24px

### Grid & Container
- Max content width centered
- Feature sections alternate between white cards and colorful swatch backgrounds
- Card grids: 2–3 columns on desktop
- Full-width colorful sections break the grid

### Border Radius Scale
| Name | Value | Use |
|------|-------|-----|
| Sharp | 4px | Ghost buttons, inputs |
| Standard | 8px | Small cards, images, links |
| Badge | 11px | Tag badges |
| Card | 12px | Standard cards, buttons |
| Feature | 24px | Feature cards, images, panels |
| Section | 40px | Large sections, footer, containers |
| Pill | 1584px | CTAs, pill-shaped buttons |

---

## 6. Depth & Elevation

| Level | Treatment | Use |
|-------|-----------|-----|
| Flat (0) | No shadow, cream canvas | Page background |
| Layered Shadow (1) | `rgba(0,0,0,0.1) 0px 1px 1px, rgba(0,0,0,0.04) 0px -1px inset, rgba(0,0,0,0.05) 0px -0.5px` | Cards, buttons |
| Hover Hard (2) | `rgb(0,0,0) -7px 7px` | Hover state |
| Focus (3) | `rgb(20, 110, 245) solid 2px` | Keyboard focus ring |

**Shadow Philosophy**: The shadow system is three-layered — a downward cast (`0px 1px 1px`), an upward inset highlight (`0px -1px 1px inset`), and a subtle edge (`0px -0.5px 1px`). Elements feel both raised and embedded. The hover hard shadow (`-7px 7px`) is deliberately retro-graphic, referencing print-era drop shadows.

---

## 7. Do's and Don'ts

### Do
- Use warm cream (`#faf9f7`) as the page background — the warmth is the identity
- Apply all 5 OpenType stylistic sets on Roobert headings: `"ss01", "ss03", "ss10", "ss11", "ss12"`
- Use the named swatch palette (Matcha, Slushie, Lemon, Ube, Pomegranate, Blueberry) for section backgrounds
- Apply the playful hover animation: `rotateZ(-8deg)`, `translateY(-80%)`, hard shadow `-7px 7px`
- Use warm oat borders (`#dad4c8`) — not neutral gray
- Mix solid and dashed borders for visual variety
- Use generous radius: 24px for cards, 40px for sections
- Use weight 600 exclusively for headings, 500 for UI, 400 for body

### Don't
- Don't use cool gray backgrounds — the warm cream (`#faf9f7`) is non-negotiable
- Don't use neutral gray borders (`#ccc`, `#ddd`) — always use the warm oat tones
- Don't mix more than 2 swatch colors in the same section
- Don't skip the OpenType stylistic sets — they define Roobert's character
- Don't use subtle hover effects — the rotation + hard shadow is the signature interaction
- Don't use small border radius (<12px) on feature cards — the generous rounding is structural
- Don't use standard blur-based shadows — use hard offset and multi-layer inset only
- Don't forget the uppercase labels with 1.08px tracking — they're the wayfinding system

---

## 8. Responsive Behavior

### Breakpoints
| Name | Width | Key Changes |
|------|-------|-------------|
| Mobile Small | <479px | Single column, tight padding |
| Mobile | 479–767px | Standard mobile, stacked layout |
| Tablet | 768–991px | 2-column grids, condensed nav |
| Desktop | 992px+ | Full layout, 3-column grids, expanded sections |

### Collapsing Strategy
- Hero: 80px → 60px → smaller display text
- Feature sections: multi-column → stacked
- Colorful sections: maintain full-width but compress padding
- Card grids: 3-column → 2-column → single column

---

## 9. Quick Reference

### Color Cheatsheet
| Role | Token | Value |
|------|-------|-------|
| Background | Warm Cream | `#faf9f7` |
| Text | Ink | `#000000` |
| Secondary text | Warm Silver | `#9f9b93` |
| Border | Oat Border | `#dad4c8` |
| Green accent | Matcha 600 | `#078a52` |
| Cyan accent | Slushie 500 | `#3bd3fd` |
| Gold accent | Lemon 500 | `#fbbd41` |
| Purple accent | Ube 800 | `#43089f` |
| Pink accent | Pomegranate 400 | `#fc7981` |

### Iteration Checklist
1. Start with warm cream (`#faf9f7`) — never cool white
2. Swatch colors are for full sections, not small accents — go bold with Matcha, Slushie, Ube
3. Oat borders (`#dad4c8`) everywhere — dashed variants for decoration
4. OpenType stylistic sets are mandatory on all Roobert headings
5. Hover animations are the signature — rotation + hard shadow, not subtle fades
6. Generous radius: 24px cards, 40px sections — nothing looks sharp or corporate
7. Three weights: 600 (headings), 500 (UI), 400 (body) — strict roles
