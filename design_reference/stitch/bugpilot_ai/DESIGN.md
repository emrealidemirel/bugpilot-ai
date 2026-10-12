---
name: BugPilot AI
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#464554'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#767586'
  outline-variant: '#c7c4d7'
  surface-tint: '#494bd6'
  primary: '#4648d4'
  on-primary: '#ffffff'
  primary-container: '#6063ee'
  on-primary-container: '#fffbff'
  inverse-primary: '#c0c1ff'
  secondary: '#555f6d'
  on-secondary: '#ffffff'
  secondary-container: '#d6e0f1'
  on-secondary-container: '#596372'
  tertiary: '#555c6e'
  on-tertiary: '#ffffff'
  tertiary-container: '#6e7487'
  on-tertiary-container: '#fefcff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e1e0ff'
  primary-fixed-dim: '#c0c1ff'
  on-primary-fixed: '#07006c'
  on-primary-fixed-variant: '#2f2ebe'
  secondary-fixed: '#d9e3f4'
  secondary-fixed-dim: '#bdc7d8'
  on-secondary-fixed: '#121c28'
  on-secondary-fixed-variant: '#3e4755'
  tertiary-fixed: '#dce2f7'
  tertiary-fixed-dim: '#c0c6db'
  on-tertiary-fixed: '#141b2b'
  on-tertiary-fixed-variant: '#404758'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '600'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  code-sm:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '450'
    lineHeight: 18px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  margin-mobile: 16px
  gutter-mobile: 12px
---

## Brand & Style
The design system is rooted in **Modern Minimalism**, specifically tailored for high-performance developer workflows. It prioritizes clarity, speed, and reduced cognitive load. The aesthetic is "Work-Bench Professional"—taking heavy inspiration from the utility-first interfaces of Linear and Vercel.

The brand personality is precise, intelligent, and unobtrusive. It avoids decorative elements in favor of functional density and mathematical spacing. The UI should feel like a high-end tool: sharp, responsive, and reliable.

## Colors
The palette is dominated by a clean white and light gray foundation to maximize legibility. 
- **Primary:** Indigo is used sparingly for primary actions and active states to guide focus without overwhelming the user.
- **Surface:** The background uses a subtle off-white (`#f9fafb`) to soften the screen glow, while pure white is reserved for cards and elevated surfaces.
- **Semantic:** Accents for severity (Green to Red) use a medium-vibrancy scale that stands out clearly against the neutral backdrop but remains professional.

## Typography
The system uses **Inter** for all UI elements to ensure maximum readability and a modern, neutral feel. We utilize a tight tracking (letter-spacing) on headings to mimic the "Linear" look. 

**JetBrains Mono** is utilized strictly for technical data, including log snippets, stack traces, and bug IDs. This creates a clear visual distinction between "System UI" and "Technical Content." Use `label-caps` for section headers and metadata labels to establish a strong hierarchy.

## Layout & Spacing
The system follows a strict **8px grid**. Padding and margins should always be multiples of 8 (or 4 for micro-adjustments). 

For this mobile application:
- **Margins:** Use a 16px safe area on the left and right edges.
- **Stacking:** Vertical elements in a list should have 12px or 16px of separation.
- **Density:** High density is preferred. Information should be grouped into cards with 12px internal padding to maintain a compact, "pro-tool" feel.

## Elevation & Depth
This design system uses **Low-contrast outlines** combined with **Ambient shadows** to define depth.
- **Borders:** Every card and interactive element uses a 1px border (`#e5e7eb`). This provides structure without the visual weight of heavy shadows.
- **Shadows:** Use a single, soft "sm" shadow (0 1px 2px 0 rgba(0, 0, 0, 0.05)) for cards. On interaction (tap), elevation does not increase; instead, the border color slightly darkens or the background subtlely shifts.
- **Layers:** Use tonal layering. The base background is `#f9fafb`, and interactive cards are `#ffffff`.

## Shapes
A consistent **14px corner radius** (`rounded-lg` in this system) is used for all main cards and input fields. This softened geometry balances the clinical nature of the typography. 
- Smaller elements like tags and badges use a 6px radius.
- Buttons maintain the 14px radius to match input fields, creating a unified form language.

## Components
- **Buttons:** Primary buttons use a solid Indigo background with white text. Secondary buttons are outlined (1px `#e5e7eb`) with charcoal text. No gradients.
- **Badges:** Use "Soft-filled" styles for severity. For example, a "Critical" badge has a light red background (10% opacity) with a bold red text. Borders on badges are optional but should be 0.5px if used.
- **Inputs:** 14px rounded corners, 1px border, with a focus state that adds a 2px Indigo ring or simply changes the border color to Indigo.
- **Cards:** White background, 1px border, 14px radius, and a 2px bottom shadow.
- **Lists:** Use thin dividers (0.5px `#f3f4f6`) between list items. Every item should have a clear chevron if it leads to a detail view.
- **Icons:** Use 24px viewBox icons with a 1.5px or 2px stroke weight. Avoid filled icons unless indicating an "active" bottom navigation state.
- **Log Viewer:** A specialized component using a dark `#111827` background and JetBrains Mono text for code snippets and console outputs.