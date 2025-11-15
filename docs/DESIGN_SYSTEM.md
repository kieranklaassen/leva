# LEVA Design System - "Laboratory Elegance"

A minimal, pure CSS design system with warm amber accents and precision aesthetics.

## Philosophy

**Laboratory Elegance** combines the precision and clarity of scientific instruments with warmth and humanity. No frameworks, no build process - just clean CSS and Rails partials.

**Design Principles:**
- Minimal color palette (warm neutrals + amber accent)
- Generous whitespace for clarity
- Technical typography (IBM Plex Mono)
- Subtle animations suggesting precision
- Signature "measurement" aesthetic for data visualization

## Colors

### Neutrals (Warm blacks and grays)
- `--neutral-950` to `--neutral-50` (10 shades)
- True blacks, not blue-tinted

### Amber Accent (Signature color)
- `--amber-900` to `--amber-400` (6 shades)
- Suggests illumination and discovery
- Use sparingly for maximum impact

### Semantic
- `--error`: Red for errors only
- `--success`: Green for completion

## Typography

### Font Families
```css
--font-display: "IBM Plex Mono", "Courier New", monospace;  /* Headers */
--font-body: -apple-system, BlinkMacSystemFont, sans-serif;  /* Body text */
--font-mono: ui-monospace, "Cascadia Code", monospace;       /* Code */
```

### Headings
- Use `<h1>` through `<h6>` - they're styled by default
- Add `.text-accent` class for amber gradient text

### Utilities
- `.text-muted` - Neutral-400 for secondary text
- `.text-mono` - Monospace with tabular numbers

## Layout Classes

### Containers
```html
<div class="container">
  <!-- Max-width 1200px, centered -->
</div>
```

### Stacks (Vertical spacing)
```html
<div class="stack">      <!-- 16px (--space-4) gaps -->
<div class="stack-lg">   <!-- 32px (--space-8) gaps -->
```

### Clusters (Horizontal spacing)
```html
<div class="cluster">    <!-- Flex row with wrapping -->
```

### Split (Space between)
```html
<div class="split">      <!-- Justify-between -->
```

### Grids
```html
<div class="grid grid-2"> <!-- Responsive 2-column -->
```

## Components (Partials)

### Buttons

```erb
<%= render "leva/shared/button",
  text: "Run Experiment",
  variant: "primary" %>

<%= render "leva/shared/button",
  text: "Cancel",
  variant: "secondary",
  size: "sm" %>

<%= render "leva/shared/button",
  text: "View",
  variant: "ghost" %>
```

**Variants:** `primary` (amber), `secondary` (neutral), `ghost` (transparent)
**Sizes:** `sm`, `md` (default), `lg`

### Cards

```erb
<%= render "leva/shared/card" do %>
  <h3>Card Title</h3>
  <p>Content here...</p>
<% end %>

<%= render "leva/shared/card", elevated: true do %>
  <!-- Adds shadow for prominence -->
<% end %>

<%= render "leva/shared/card", measure: true do %>
  <!-- Adds amber measurement line accent -->
<% end %>
```

**Options:**
- `elevated: true` - Adds shadow
- `measure: true` - Adds signature amber line
- `class: "..."` - Additional CSS classes

### Score Meter (Signature Component)

The standout element - displays metrics with precision instrument aesthetics.

```erb
<%= render "leva/shared/score_meter",
  score: 0.87,
  label: "Accuracy" %>

<%= render "leva/shared/score_meter",
  score: 42,
  max: 100,
  label: "Total Points" %>
```

**Features:**
- Animated amber gradient fill
- Auto-calculates percentage
- Color-coded (low/mid/high)
- Tabular numeric display

## Direct CSS Classes

### Badges

```html
<span class="badge">Default</span>
<span class="badge badge-amber">Active</span>
<span class="badge badge-success">Complete</span>
<span class="badge badge-error">Failed</span>
```

### Tables

Tables are styled by default - just use semantic HTML:

```html
<table>
  <thead>
    <tr><th>Column</th></tr>
  </thead>
  <tbody>
    <tr><td>Data</td></tr>
  </tbody>
</table>
```

### Forms

Inputs are styled by default:

```html
<label>Email</label>
<input type="email" placeholder="you@example.com">

<label>Message</label>
<textarea></textarea>
```

## Animations

### Built-in Animations

- `.fade-in` - Fade in with slight upward motion
- `.pulse-amber` - Subtle amber pulsing
- Score meters auto-animate on render

### Custom Animations

Use CSS variables for consistency:

```css
.my-element {
  transition: all var(--transition-base);
}
```

## Spacing Utilities

```html
<div class="mb-4">  <!-- Margin-bottom: 16px -->
<div class="mt-6">  <!-- Margin-top: 24px -->
<div class="p-6">   <!-- Padding: 24px -->
```

**Available:** `mb-2`, `mb-4`, `mb-6`, `mb-8`, `mt-2`, `mt-4`, `mt-6`, `mt-8`, `p-4`, `p-6`, `p-8`

## Example Usage

```erb
<div class="container">
  <div class="stack-lg">

    <h1 class="text-accent">Experiment Results</h1>

    <%= render "leva/shared/card", measure: true do %>
      <h3>Model Performance</h3>
      <div class="stack">
        <%= render "leva/shared/score_meter", score: 0.92, label: "Accuracy" %>
        <%= render "leva/shared/score_meter", score: 0.87, label: "F1 Score" %>
      </div>
    <% end %>

    <div class="split">
      <h3>Actions</h3>
      <div class="cluster">
        <%= render "leva/shared/button", text: "New Run", variant: "primary" %>
        <%= render "leva/shared/button", text: "Export", variant: "secondary" %>
      </div>
    </div>

  </div>
</div>
```

## Design System Reference

See `app/views/leva/shared/_example_page.html.erb` for a complete showcase of all components and patterns.

## CSS Variables Reference

All design tokens are defined as CSS custom properties in `:root`:

```css
:root {
  --neutral-950: #0a0a0a;  /* Darkest background */
  --neutral-800: #262626;  /* Card backgrounds */
  --neutral-400: #a3a3a3;  /* Muted text */
  --amber-600: #d97706;    /* Primary actions */
  --space-4: 1rem;         /* 16px */
  --radius-md: 0.5rem;     /* 8px */
  /* ... and more */
}
```

Use them in your custom CSS:

```css
.my-component {
  background: var(--neutral-900);
  color: var(--amber-400);
  padding: var(--space-6);
  border-radius: var(--radius-lg);
}
```

## No Build Process Required

This design system uses:
- ✅ Pure CSS (no Sass, PostCSS, or Tailwind compilation)
- ✅ Rails partials (no ViewComponent gem)
- ✅ System fonts (fallback to web-safe fonts)
- ✅ Data URI for grain texture (no image files)

**To use:** Just include the stylesheet in your layout - that's it!

```erb
<%= stylesheet_link_tag "leva/application", "data-turbo-track": "reload" %>
```
