# BugPilot branding

- `bugpilot_logo.png`: transparent horizontal logo for the application UI.
- `bugpilot_symbol.png`: transparent, text-free emblem.
- `bugpilot_app_icon.png`: opaque 1024px launcher icon on a navy background.

The two transparent masters were edited with the built-in imagegen tool.
Platform size/format conversion is reproducible on macOS:

```sh
swift tool/generate_icons.swift
```

The script updates iOS, Android (including adaptive foregrounds), macOS,
Windows ICO and web icons. iOS icons are RGB without alpha. Android adaptive
icons use additional safe padding so launcher masks do not clip the emblem.

## Final imagegen prompts

Horizontal logo:

> Edit the provided logo into a perfectly clean flat vector-style PNG with transparent background. Preserve exact bug/plane symbol geometry on left and bold 'BugPilot AI' lettering on right, original purple colors and original layout. Remove white matte/background completely including holes; ZERO fringe, ZERO noise, ZERO speckles, ZERO texture, ZERO gradient, ZERO shadows. Solid uniform purple fills and smooth precise antialiased edges only. Wide horizontal image closely framed around logo. This must be crisp professional production logo artwork, not a photographic rendering.

Symbol:

> Use case: precise-object-edit. Create a symbol-only app icon asset from the provided BugPilot AI logo. REMOVE ALL TEXT 'BugPilot AI'. Keep ONLY the original purple bug/paper-plane emblem from the left. Preserve its precise geometry, rounded strokes, two curved antennae, symmetric open triangular wings and pointed lower diamond, original periwinkle purple color. Center this one symbol on a square transparent canvas with 12% padding on every side. Clean smooth flat solid-color vector-style edges. Genuine transparent background including holes. Absolutely no white halo, no lettering, no texture or speckles, no shadows, no background tile, no mockup. Production quality crisp icon.
