# AGENT.md — Astral UI Architecture, Design Process & Technical Analysis

> **Project:** Astral UI  
> **Target Environment:** Roblox Client Runtime (Luau / Exploits / Script Hubs)  
> **Primary File:** `Astral.lua` (~21,200+ lines monolithic core)  
> **Supporting Files:** `Docs.md`, `Example.lua`, `LucideIcons.lua`, `addons/SaveManager.lua`, `addons/ThemeManager.lua`

---

## 1. Project Overview & Design Philosophy

**Astral UI** is a desktop-class, high-fidelity Roblox GUI framework engineered primarily for execution in client-side script environments. Unlike standard game-packaged Roact/Fusion frameworks, Astral operates under strict distribution constraints:
- **Atomic Single-Script Delivery:** Must execute cleanly through a single `loadstring(game:HttpGet(...))()` invocation with zero external asset dependencies or complex module bundlers.
- **DPI-Aware Responsive Rendering:** Dynamic multi-resolution scaling ensuring parity across 1080p, 1440p, 4K, and mobile viewport touch interfaces.
- **Cohesive Modern Aesthetic:** Heavily inspired by modern desktop design systems (glassmorphism, subtle linear gradients, rounded corners, crisp Lucide iconography, micro-animations via `TweenService`).
- **Complete Feature Completeness:** Houses an entire suite of controls (toggles, multi-select searchable dropdowns, color pickers, numeric steppers, weighted dynamic tables, embedded media players, and draggable widgets).

---

## 2. Core Architectural Systems

```
+-------------------------------------------------------------------------+
|                              Astral Core                                |
+-----------------------------------+-------------------------------------+
| Dynamic Theme & Style Registry    | Viewport & DPI Scaling Engine       |
| (AddToRegistry, StyleRoots)       | (DPIScale, NewTrackedScale)         |
+-----------------------------------+-------------------------------------+
| Layered Z-Index Virtualization    | Monolithic Control Factory          |
| (Base -> Overlays -> Dialogs)     | (Funcs:AddToggle, AddDropdown, ...) |
+-----------------------------------+-------------------------------------+
                                    |
                                    v
+-------------------------------------------------------------------------+
|                           Addons & Persistence                          |
+-----------------------------------+-------------------------------------+
| SaveManager (JSON Config Engine)  | ThemeManager (Palette Presets)      |
+-----------------------------------+-------------------------------------+
```

### 2.1 The Dynamic Theme & Style Registry
To avoid expensive descendant traversal during theme switches, Astral implements an observer/registry pattern:
- **`Library.Registry`:** Weak-keyed metatable mapping UI instances to registered properties (`BackgroundColor3`, `TextColor3`, `ImageColor3`, etc.).
- **`Library:AddToRegistry(Inst, Props)`:** Registers properties by token (e.g. `"BackgroundColor"`, `"MainColor"`, `"AccentColor"`, `"OutlineColor"`).
- **`Library:UpdateTheme()`:** Sweeps the registry and batch-applies new `Color3` values instantly without rebuilding the DOM.
- **`StyleRoots` & Gradient Propagation:** Overlays, menus, dialogs, and popout windows are registered as style roots via `Library:AddStyleRoot(Root)`. When gradients and transparency are active, the system calculates relative opacity to prevent "double-transparency" visual artifacts.

### 2.2 Layered Z-Index Virtualization
Roblox's `ZIndex` handling often suffers from sibling clipping when dealing with floating menus, search overlays, and dropdown lists. Astral solves this by reserving distinct Z-Index bands:
- `BaseZIndex` (Default: ~1) -> Window background, headers, sidebar.
- `ContentZIndex` (~5 - 10) -> Standard section controls, buttons, toggles.
- `DropdownZIndex` (~50) -> Active opened dropdown lists.
- `SearchOverlayZIndex` (~100) -> Global command / search overlay.
- `DialogContentZIndex` (~200) -> Modal confirmation dialogs and blocking prompts.
- `TooltipZIndex` (~300) -> Hover tooltips (always top-level).
- `WatermarkZIndex` (~400) -> Pinned status and FPS/ping overlays.

### 2.3 Layout & DPI Math
Because standard Roblox `Scale` coordinates distort when aspect ratios change, Astral builds entirely on `Offset` math combined with dynamic scaling:
- **`Library.DPIScale`:** Global scalar (typically 0.8x to 1.5x) derived from screen resolution and user settings.
- **`Library:GetTextBounds()`:** Measures text dimensions ahead of time using `TextService:GetTextSize` to calculate minimum column widths, draggable button frames, and label offsets deterministically.

---

## 3. Engineering Evolution & Problem-Resolution Log

### 3.1 The Patchy Gradient Problem (Dark/Muddy Layering)
* **Problem:** In early revisions, nesting multiple semi-transparent frames (`0.55` panel transparency over `0.3` card transparency over a gradient background) resulted in an uneven, muddy look. Dropdown containers and section cards appeared disjointed and patchy.
* **Analysis:** Opacity multiplication in visual compositing means $T_{final} = 1 - (1 - T_1)(1 - T_2)$. Heavy panel transparency washes out contrast and allows underlying layout gaps to show through.
* **Resolution:** 
  - Reduced `GradientPanelTransparency` and `GradientCardTransparency` to `0.1` (90% opaque).
  - Softened the color gradient lerp factor ($0.05 - 0.08$ instead of $0.16$) with background offset `-2`.
  - Result: All panels, context menus, and overlays share a solid, cohesive tone while retaining a subtle, sleek linear sheen.

### 3.2 Dropdown Visuals & Joint Artifacts
* **Problem:** The original implementation attempted to give opened dropdowns the illusion of being fused with their selection boxes using `SquareCorners` hacks and $-1\text{px}$ layout offsets. This produced visible square border glitches and misalignment, especially on non-integer DPI scales.
* **Analysis:** Synthetic corner squaring via clipping masks creates rasterization artifacts on Roblox's UI renderer, particularly when borders (`UIStroke`) are attached.
* **Resolution:**
  - Removed `DisplayJoint` and synthetic `SquareCorners` calls.
  - Positioned `ListShell` and `ActionRow` flush at `UDim2.fromOffset(0, 0)`.
  - Let native `UICorner` provide clean independent rounding for both closed boxes and dropdown menus.

### 3.3 Label Alignment & Icon Positioning
* **Problem:** Left-sided dropdown boxes (`BoxSide = "Left"`) had left-aligned labels that ran directly into the box. Additionally, icon tiles placed next to subtext were hard-coded to a top offset (`UDim2.fromOffset(0, 2)`), causing icons to be misaligned with multi-line text blocks.
* **Resolution:**
  - Applied conditional `TextXAlignment = BoxOnLeft and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left` across both main label and subtext in `Funcs:AddDropdown`.
  - Updated icons in both `Funcs:AddDropdown` and `Funcs:AddStepper` to `AnchorPoint = Vector2.new(0, 0.5)` and `Position = UDim2.new(0, 0, 0.5, 0)` for consistent vertical centering.

### 3.4 Table Column Clipping & Text Measurements
* **Problem:** Table headers and data cells collapsed below legible dimensions when container widths shrunk, causing text overflow into adjacent columns.
* **Analysis:** Column flex weighting (`Weight / TotalWeight`) does not account for content intrinsic size when free space is constrained.
* **Resolution:**
  - Integrated `Measure(Column.Name, 12) + 16` as an irreducible lower bound (`MinWidth`).
  - Enforced `ClipsDescendants = true` on every individual table cell frame (`MakeCell`).

### 3.5 Settings Gear Sizing & Hitboxes
* **Problem:** Sub-element settings gears (`ParentObj:AddSettings()`) were rendered off-screen on toggle switches because their anchor point was set without a matching position.
* **Resolution:** Assigned `Gear.Position = UDim2.new(1, -4, 0.5, 0)` with anchor `(1, 0.5)` so it cleanly docks directly left of the switch mechanism.

### 3.6 Draggable Button Dimensioning (Oversized Bounds)
* **Problem:** `Table:SetText` in `Library:AddDraggableButton` sized the button using `UDim2.fromOffset(X * 2, Y * 2)`. This inflated draggable buttons to twice the measured text size, creating massive empty whitespace and awkward hitboxes.
* **Analysis:** Text measurement bounds already return the exact bounding box needed. Sizing with linear multipliers scales exponentially with longer text strings.
* **Resolution:** Changed button sizing to `UDim2.fromOffset(X + 24, Y + 12)`, providing consistent 12px horizontal and 6px vertical padding around the text.

### 3.7 Sidebar Cleanliness & Scrollbar Elimination
* **Problem:** The sidebar tabs frame (`Tabs`) had `Library:AddCustomScrollbar(Tabs)` attached by default, which added visual noise and distracted from the sleek modern desktop sidebar layout.
* **Resolution:** Removed the custom scrollbar attachment from `Tabs`. The frame remains natively scrollable via `AutomaticCanvasSize.Y` with a hidden scrollbar thickness (`ScrollBarThickness = 0`).

### 3.8 Search Overlay Theme & Style Root Inheritance
* **Problem:** The global command/search overlay (`SearchOverlay`) was not enrolled as a style root. When master window transparency and gradients were adjusted, the search overlay failed to adapt properly.
* **Resolution:** Registered `Library:AddStyleRoot(SearchOverlay)` directly after `AddToRegistry`, allowing the search modal to automatically synchronize with the window gradient and opacity stack.

---

## 4. Control Taxonomy & Feature Matrix

| Control | Identifier / Key | Capabilities |
| :--- | :--- | :--- |
| **Toggle / Checkbox** | `AddToggle` | State animation, subtext, risky flag, gear settings panel, keybind attachment |
| **Slider** | `AddSlider` | Precise float rounding, custom prefix/suffix, click-to-type, drag scrubbing |
| **Stepper** | `AddStepper` | Discrete increment/decrement buttons, holdable rapid-firing, icons, formatting |
| **Dropdown** | `AddDropdown` | Single/multi-select, search filtering, player thumbnails, custom icon mappings |
| **ColorPicker** | `AddColorPicker` | HSV spectrum, alpha channel slider, hex input box, clipboard copy/paste |
| **Keybind** | `AddKeybind` | Mode switching (Hold, Toggle, Always), keybind display menu, blacklist |
| **Table** | `AddTable` | Dynamic auto/fill column weighting, row selection callbacks, clipping |
| **Draggable** | `AddDraggable*` | Viewport-safe dragging, title measurement sizing, visibility toggles |
| **Custom Tab** | `AddCustomTab` | Unmanaged container (`Tab.CustomContainer`) for raw Roblox `GuiObject` hosting |

---

## 5. Addons Architecture

### 5.1 SaveManager (`addons/SaveManager.lua`)
- **Format:** Human-readable JSON formatted via `HttpService:JSONEncode`.
- **Target Tracking:** Automatically indexes all elements registered in `Library.Toggles` and `Library.Options` that have defined indexes and aren't flagged as excluded.
- **Autoload Logic:** Compares current game `PlaceId` / `JobId` against saved config files in `Astral/settings/` on the exploit file system (`writefile`, `readfile`, `isfolder`).

### 5.2 ThemeManager (`addons/ThemeManager.lua`)
- **Theme Format:** Dictionary of primary colors (`BackgroundColor`, `MainColor`, `AccentColor`, `OutlineColor`, `FontColor`).
- **Presets:** Ships with built-in presets (Dark, Light, Midnight, Nordic, Dracula, Cyberpunk, Rose).
- **Custom Themes:** Serializes custom color selections and applies them in real-time across the entire UI via `Library:UpdateTheme()`.

---

## 6. Guidelines for AI Agents & Developers Modifying Astral

When working on `Astral.lua`, observe these strict rules:

1. **Monolithic Integrity:**
   - Do not split `Astral.lua` into external module files unless specifically requested; script execution environments depend on the entire library arriving as one self-contained string.
2. **Registry Discipline:**
   - Whenever instantiating a new colored UI element (`Frame`, `TextLabel`, `ImageLabel`, `UIStroke`), **always** call `Library:AddToRegistry(element, { ... })`. Never hardcode colors that should adapt to user themes.
3. **Corner Radius Multipliers:**
   - Use `Library.CornerRadius` or `Library.CornerRadius / 2` with `UICorner` to keep roundness uniform throughout the interface.
4. **Clean Disposal:**
   - Ensure event connections are tracked or cleaned up when containers are destroyed to prevent memory leaks during long exploit sessions.
5. **No Blind Global Overwrites:**
   - All state must reside in `Library` tables (`Library.Toggles`, `Library.Options`, `Library.Tabs`, etc.).
6. **Continuous Documentation Updates (`AGENT.md`):**
   - **MANDATORY INSTRUCTION:** After analyzing architecture, diagnosing bugs, or applying fixes to `Astral.lua` (or supporting files), always update `AGENT.md` with:
     - The root cause analysis and rationale behind the changes.
     - Exact resolutions and visual/functional impact.
     - Any newly established design guidelines or architectural patterns.

---

## 7. Change Log & Maintenance History

### 2026-11-10: Development Fork Refactoring (`inCythe/AstralDev`)
- **Rationale / Root Cause:** The codebase was branched into a dedicated development repository (`inCythe/AstralDev`) for active iteration and testing. Hardcoded raw GitHub URLs previously pointed to the upstream production repository (`inCythe/Astral`), causing development builds to load production assets and modules rather than dev versions.
- **Resolutions:**
  - `Astral.lua`: Updated `BaseURL` and `LUCIDE_SOURCE_URL` to point to `inCythe/AstralDev/refs/heads/main/`. Built-in asset paths (`TransparencyTexture`, `SaturationMap`, `LoadingIcon`, `CheckIcon`, `AstralIcon`, `DiscordIcon`) automatically resolve to the dev repository.
  - `Example.lua`: Updated `HttpGet` fallback loaders for `Library`, `SaveManager`, and `ThemeManager` to load from `inCythe/AstralDev/refs/heads/main/`.
  - `Docs.md`: Updated all documentation loadstring and example snippets to reference `inCythe/AstralDev`.
- **Impact:** Testing and running the library now pulls directly from the `AstralDev` repository, isolating development testing from production.
