# UI Design Spec — Astral Modern Glass UI

**Source:** Reference screenshots (Meet AI Analytics + Productivity Dashboard)  
**Goal:** A centralized, cohesive, modern glass UI/UX for the Astral framework that replaces the patchy gradients and inconsistent all-corner rounding with a deliberate, theme-derived design system.

---

## 1. Visual Direction

| Attribute | Direction |
|-----------|-----------|
| **Style** | Modern glassmorphism — dark, deep panels with subtle transparency, crisp edges, restrained glow |
| **Theme** | Dark-first. Deep navy / near-black backgrounds with vibrant, in-family gradient accents |
| **Mood** | Focused, premium, smooth, calm but energetic where accents appear |
| **Lighting** | Soft edge highlights and inner glows on cards; no heavy drop shadows that muddy the layout |
| **Motion** | Smooth `TweenService` fades (0.2–0.35s), subtle hover lifts, no strobing or excessive bounce |

---

## 2. Color Palette (Derived from Reference Images)

The four base tokens below drive *every* surface. All other colors are derived from them in `Library:SyncDesign()` so a theme change or color picker keeps the whole UI in sync.

### Base tokens
```
BackgroundColor  = #0D0D10   # Deep window backdrop (base layer)
MainColor        = #151519   # Controls / inputs / cards (interactive surface)
AccentColor      = #4287F5   # Primary brand accent (selection, progress, primary action)
OutlineColor     = #24242A   # Borders and separators
FontColor        = #FFFFFF   # Primary text
```

### Derived surface hierarchy
| Token | Meaning | Usage |
|-------|---------|-------|
| `PanelColor` | Slightly lighter than background | Sections, dialogs, dropdowns, popouts (containers) |
| `PanelRaisedColor` | Lighter still | Raised cards, active tab surfaces |
| `PanelSunkenColor` | Darker than background | Nested sub-sections, recessed areas |
| `AccentColor2` | Related secondary hue | Gradient end, soft highlights |
| `AccentSoftColor` | Accent tinted into panel | Active tab, selection state |
| `OutlineSoftColor` | Muted outline | Subtle separators on glass panels |
| `TextMutedColor` | Desaturated font | Subtext, captions, secondary labels |
| `GradientStartColor` | Window gradient start | Top of window gradient |
| `GradientEndColor` | Window gradient end | Bottom of window gradient |

### Accent families (from images)
- **Meet AI:** Deep purple / magenta / neon pink accents (`#B000FF` → `#FF00D0`)
- **Productivity:** Blue → purple → orange gradient ring accents
- **Implementation:** Keep the accent hue chosen by the user; derive `AccentColor2` by shifting hue slightly and `AccentGradientEndColor` by lightening toward white by ~20–24%.

---

## 3. Corner Radius System (Semantic, Not Universal)

**Problem fixed:** Previously every frame used `UICorner` rounding all four corners, which created visual errors where nested surfaces fought each other (e.g. a panel inside an all-rounded window leaving awkward inner seams).

**Rule:** Round only the edge(s) that need it. Nested surfaces step down one size.

| Kind | Radius | Use case |
|------|--------|----------|
| `Window` | `Library.CornerRadius` (default 12, max 20) | Outer window only |
| `Panel` | `Window - 2` (default 10) | Sections, dialogs, dropdowns, popouts |
| `Control` | `floor(Window * 0.6)` clamped 4–8 | Buttons, inputs, toggles, sliders |
| `Small` | `floor(Window * 0.4)` clamped 3–6 | Badges, pills, small icons |
| `Pill` | `999` | Fully rounded progress rings, active indicators |

**Top-only / Bottom-only edges:**  
The window's top strip and footer are single fills clipped by a cap frame:
- **Top strip:** Rounded on the **top** edge only; bottom edge is square so it meets the content cleanly.
- **Footer:** Rounded on the **bottom** edge only; top edge is square.
- Implemented via `Library:AddEdgeFill(Frame, "top"|"bottom", ...)` — draws a fill `Radius` taller than the container, parent clips the overflow, far corners are cut away.

**Sidebar:** Flush against window edges, **no** `UICorner` of its own — the window clip shapes the outer corners, preventing double-rounded seams.

**Tabs:** `TabButtonsStyle.CornerRadius = 8` (small, active tab gets `AccentSoftColor` fill).

---

## 4. Gradient Background (Theme-Driven, Not Patchy)

**Problem fixed:** The old bitmap `Gradient.png` layer stacked on top of a color gradient created a muddy, off-palette, patchy look, especially under transparency.

**Solution:** Remove the bitmap artwork layer entirely. Paint the backdrop with a single, theme-derived **three-stop color gradient**:

```
Stop 0.00  = GradientStartColor      (near background, brightest)
Stop 0.55  = BackgroundColor         (anchored mid-tone — the theme color)
Stop 1.00  = GradientEndColor        (subtle accent-leaning tint)
```

- Rotation configurable (default 45°).
- Transparency follows `WindowTransparency` via `NumberSequence`.
- Overlay roots (menus, dialogs, popouts) receive the same sequence so floating surfaces never look pasted on.
- The gradient is clamped (`ClampTowards`) so the end color never drifts more than ~26 from the background — preserving text contrast.

---

## 5. Layout Structure

```
Window (MainFrame, ClipsDescendants)
├── GradientOverlay            (theme-derived 3-stop gradient, full size)
├── TopBar (48px)
│   ├── TopBackgroundCap       (clips top edge, rounded top corners only)
│   │   └── TopBackground      (PanelColor, top-rounded)
│   └── TopFlatBottom          (PanelColor, square bottom, meets content)
│   ├── Title / Subtitle block (centered or left-aligned per TitleAlignment)
│   ├── Icon
│   ├── Search box (control radius, PanelColor fill)
│   └── Window controls        (Minimize / Close — control radius, MainColor)
├── DividerLine (1px OutlineColor)
├── Sidebar (flush left, PanelColor, no self-corner radius)
│   ├── Tab buttons (control radius, active = AccentSoftColor)
│   └── Section headers (uppercase, small, muted)
├── Container (content area)
│   ├── Tabs
│   │   └── Sections
│   │       └── SectionHolder (PanelColor, panel radius)
│   │           └── SectionContainer (controls)
│   └── WarningBox (PanelColor, panel radius)
└── BottomBackground (clips bottom edge, rounded bottom corners only)
    └── BottomFill             (PanelColor, bottom-rounded)
    └── BottomBar (footer slots L / C / R)
```

**Centralization:**  
- Header block centered in the sidebar header area (or left/right per config).  
- Tabs and sections stacked vertically with consistent gaps (`Design.Spacing`).  
- Footer split into Left / Middle / Right slots.  
- No floating, arbitrarily placed elements — everything aligned to a grid with `Spacing.XS/SM/MD/LG/XL`.

---

## 6. Component Treatments

| Component | Background | Radius | Border | Notes |
|-----------|-----------|--------|--------|-------|
| Window | `BetterColor(BackgroundColor, -1)` | Window | Outline (1px) | ClipsDescendants |
| Panel / Section | `PanelColor` | Panel | Outline (1px) | Glass feel |
| Card / Control | `PanelRaisedColor` | Control | Outline (1px) | Interactive surface |
| Sub-section | `PanelSunkenColor` (50% trans) | Small | none | Recessed nesting |
| Dropdown / Context menu | `PanelColor` | Panel | Outline (1px) | Style root |
| Tooltip | `PanelColor` | Small | none | Always top ZIndex |
| Dialog | `PanelColor` | Panel | Outline (1px) | Modal, centered |
| Notification | `MainColor` | Control | Outline (1px) | Toast, side-anchored |
| Active tab | `AccentSoftColor` | Control | none | Distinct from idle tabs |
| Button (primary) | `AccentColor` | Control | none | Hover = lighter accent |
| Button (ghost) | `MainColor` | Control | Outline (1px) | Secondary actions |
| Progress ring / pill | `AccentColor` gradient | Pill | none | Donut charts, focus timer |
| Input / Search | `PanelColor` | Control | Outline (1px) | Focus highlight = accent |

---

## 7. Interaction States

- **Idle:** `PanelColor` / `MainColor`, muted text.
- **Hover:** Lift toward `PanelRaisedColor`, subtle outline brighten, icon opacity to 1.
- **Active / Selected:** `AccentSoftColor` fill, accent text/icon.
- **Pressed:** Slight darken, immediate (no long tween).
- **Disabled:** `BackgroundColor` fill, `TextMutedColor` text, reduced opacity.
- **Focus (input):** Outline tinted to accent, no heavy glow ring.

All transitions use `Library.TweenInfo` (Quad, Out, ~0.1–0.22s). Reduced-motion friendly.

---

## 8. Typography

- **Family:** `GothamMedium` (configurable via `Scheme.Font`).
- **Weights:** Medium for UI, Light for subtext/captions.
- **Sizes:** Title 20, Section 15, Body 14, Subtext 12, Caption 10, Footer 14.
- **Alignment:** Section headers uppercase, letter-spaced, left-aligned. Values right-aligned in data rows.
- **RichText:** Enabled everywhere for `<b> <i> <u> <font color>` markup.

---

## 9. Accessibility & Contrast

- Minimum 4.5:1 contrast for standard text, 3:1 for large text (validated by `ThemeManager:GetContrastReport`).
- Never communicate state by color alone — pair color with icon, shape, or text label.
- Gradient end color is clamped to stay within a readable delta of the background.
- Focus states visible on all interactive controls.

---

## 10. What Changed vs Previous Astral UI

1. **Gradient:** Removed `Gradient.png` bitmap layer; replaced with a single theme-derived 3-stop color gradient that respects `WindowTransparency`.
2. **Corners:** Replaced blanket `WindowInfo.CornerRadius` on every nested frame with semantic `GetRadius(kind)` (window > panel > control > small). Top strip and footer are top-rounded / bottom-rounded only via `AddEdgeFill`.
3. **Palette:** Introduced `PanelColor`, `PanelRaisedColor`, `PanelSunkenColor`, `AccentColor2`, `AccentSoftColor`, `TextMutedColor` — all derived from the 4 base tokens in `SyncDesign()`.
4. **Tabs:** Active tabs now show `AccentSoftColor` fill instead of being invisible; `TabButtonsStyle.CornerRadius = 8`.
5. **Sidebar:** Removed self `UICorner` so it sits flush against the window clip.
6. **Surfaces:** Sections, dialogs, dropdowns, tooltips, warnings, conditional sections all moved from `BackgroundColor` to `PanelColor`/`PanelSunkenColor` for a readable three-step surface hierarchy.

---

## 11. Implementation Notes

- Call `Library:SyncDesign()` inside `Library:UpdateColorsUsingRegistry()` so theme pickers rebuild derived tokens automatically.
- `GetRadius("panel"|"control"|"small"|"pill")` should be used by any new control instead of raw `Library.CornerRadius`.
- `AddEdgeFill(parent, "top"|"bottom", colorIndex, radius, mode)` handles single-edge rounding cleanly under transparency.
- Keep `GradientTexture` references removed; the backdrop is pure `UIGradient` now.
- When adding a new frame, register it with `PanelColor` for containers, `MainColor` for controls, and the matching radius kind.
