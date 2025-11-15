# LEVA Design System - Complete Migration Plan

## Executive Summary

**Goal**: Migrate all 27 LEVA views from Tailwind CDN to the new "Laboratory Elegance" pure CSS design system with full responsive support.

**Status**: CSS Foundation Complete ✅
- Responsive breakpoints (640px, 768px, 1024px+)
- Fluid typography with `clamp()`
- 100+ utility classes
- Mobile-first layouts
- WCAG 2.1 AA compliant

**Next**: Migrate views systematically, starting with layout, then index pages, then detail pages.

---

## Migration Strategy

### Phase 1: Foundation (COMPLETED ✅)
- [x] CSS with responsive breakpoints
- [x] Fluid typography
- [x] Utility classes (display, flex, spacing, text)
- [x] Responsive tables
- [x] Touch targets (44px minimum)
- [x] Accessibility (sr-only, reduced-motion)
- [x] Empty state partial
- [x] Alert partial

### Phase 2: Layout & Navigation (IN PROGRESS)
1. **application.html.erb** - Remove Tailwind CDN, add mobile nav
2. Test layout on mobile/tablet/desktop

### Phase 3: Index Pages
3. **experiments/index.html.erb**
4. **datasets/index.html.erb**
5. **dataset_records/index.html.erb**

### Phase 4: Detail Pages
6. **experiments/show.html.erb**
7. **datasets/show.html.erb**
8. **dataset_records/show.html.erb**
9. **runner_results/show.html.erb**

### Phase 5: Forms
10. **experiments/_form.html.erb** + new/edit
11. **datasets/_form.html.erb** + new/edit
12. **Partials**: `_experiment.html.erb`, `_dataset.html.erb`

### Phase 6: Workbench (Complex)
13. **workbench/index.html.erb** - 3-panel responsive layout
14. **workbench/_prompt_sidebar.html.erb**
15. **workbench/_top_bar.html.erb**
16. **workbench/_prompt_content.html.erb**
17. **workbench/_results_section.html.erb**
18. **workbench/_evaluation_area.html.erb**
19. **workbench/_prompt_form.html.erb**
20. **workbench/new.html.erb**, **workbench/edit.html.erb**

### Phase 7: Testing & Polish
21. Responsive testing (375px, 768px, 1280px+)
22. Accessibility audit
23. Performance check

---

## Design System Mappings

### Old Tailwind → New CSS

| Old Tailwind Classes | New CSS Classes | Notes |
|---------------------|-----------------|-------|
| `bg-gray-950` | (default body) | Already applied globally |
| `bg-gray-900` | `.card` or inline `background: var(--neutral-900)` | |
| `bg-gray-800` | `.card` | Semi-transparent with backdrop blur |
| `text-indigo-400` | `.text-accent` | Amber gradient |
| `text-indigo-300` | `color: var(--amber-400)` | Inline or custom class |
| `text-gray-300` | `color: var(--neutral-300)` | |
| `text-gray-400` | `.text-muted` | |
| `rounded-lg` | `.card` (has border-radius) | |
| `shadow-lg` | `.card-elevated` | |
| `flex items-center` | `.flex .items-center` | |
| `flex justify-between` | `.split` or `.flex .justify-between` | |
| `grid grid-cols-2` | `.grid .grid-2` | Responsive by default |
| `px-4 py-8` | `.px-4 .py-8` or inline | |
| `container mx-auto` | `.container` | Responsive padding built-in |

### Button Mappings

| Old | New |
|-----|-----|
| `class="btn btn-primary flex items-center"` | `<%= render "leva/shared/button", text: "...", variant: "primary" %>` |
| Inline SVG icons in buttons | Pass SVG as `icon` parameter (coming in next iteration) |

### Card/Container Patterns

**Old Pattern:**
```erb
<div class="bg-gray-800 rounded-lg shadow-lg p-6">
  Content
</div>
```

**New Pattern:**
```erb
<%= render "leva/shared/card" do %>
  Content
<% end %>
```

**Or for inline control:**
```erb
<div class="card">
  Content
</div>
```

### Empty States

**Old Pattern:**
```erb
<div class="bg-gray-800 rounded-lg shadow-lg p-12 text-center">
  <svg class="mx-auto h-12 w-12 text-indigo-400">...</svg>
  <h3 class="mt-2 text-xl font-medium text-indigo-300">No experiments yet</h3>
  <p class="mt-1 text-gray-400">Get started...</p>
  <div class="mt-6">
    <%= link_to ... %>
  </div>
</div>
```

**New Pattern:**
```erb
<%= render "leva/shared/empty_state",
  icon: '<svg>...</svg>',
  title: "No experiments yet",
  description: "Get started by creating a new experiment.",
  button_text: "Create Experiment",
  button_href: new_experiment_path %>
```

---

## View-by-View Migration Guide

### 1. application.html.erb (CRITICAL - DO FIRST)

**Current Issues:**
- Line 9: Tailwind CDN loaded
- Line 10: Stimulus CDN (keep for now)
- Lines 17-27: Logo uses indigo gradient
- Lines 29-33: Nav uses indigo accent
- No mobile navigation

**Mobile Concerns:**
- Horizontal nav breaks <640px
- Logo + nav items don't fit on 375px screens
- Need hamburger menu

**Migration Steps:**

1. **Remove Tailwind CDN** (Line 9)
2. **Add stylesheet_link_tag** for our CSS
3. **Update logo colors** (indigo → amber)
4. **Add mobile navigation**
5. **Add skip link** for accessibility

**New Layout:**

```erb
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Leva - <%= yield(:title) || 'AI Evaluation Engine' %></title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "leva/application", "data-turbo-track": "reload" %>
    <script src="https://cdn.jsdelivr.net/npm/stimulus@3.2.2/dist/stimulus.umd.min.js"></script>
    <%= yield(:head) %>
  </head>
  <body>
    <%# Skip link for accessibility %>
    <a href="#main-content" class="sr-only focus:not-sr-only">
      Skip to main content
    </a>

    <nav class="card mb-0" style="border-radius: 0; border-left: 0; border-right: 0; border-top: 0;">
      <div class="px-4">
        <div class="flex items-center" style="min-height: 4rem;">
          <%# Logo %>
          <%= link_to root_path, class: 'flex items-center gap-2' do %>
            <svg xmlns="http://www.w3.org/2000/svg" style="width: 2rem; height: 2rem;" viewBox="0 0 24 24" fill="none" stroke="url(#gradient)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <defs>
                <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stop-color="<%= "var(--amber-500)" %>" />
                  <stop offset="100%" stop-color="<%= "var(--amber-600)" %>" />
                </linearGradient>
              </defs>
              <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" />
            </svg>
            <span class="text-accent" style="font-size: 1.5rem; font-weight: 700;">LLM Evals</span>
          <% end %>

          <%# Desktop Nav (hidden on mobile) %>
          <div class="hidden-mobile ml-10 flex gap-6">
            <%= link_to 'Workbench', workbench_index_path, class: nav_link_class(workbench_index_path) %>
            <%= link_to 'Datasets', datasets_path, class: nav_link_class(datasets_path) %>
            <%= link_to 'Experiments', experiments_path, class: nav_link_class(experiments_path) %>
          </div>

          <%# Mobile Menu Button (hidden on desktop) %>
          <button type="button"
                  class="hidden-desktop ml-auto btn btn-ghost"
                  aria-label="Toggle menu"
                  onclick="document.getElementById('mobile-menu').classList.toggle('hidden')">
            <svg xmlns="http://www.w3.org/2000/svg" style="width: 1.5rem; height: 1.5rem;" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
        </div>

        <%# Mobile Menu (hidden by default) %>
        <div id="mobile-menu" class="hidden hidden-desktop stack pb-4">
          <%= link_to 'Workbench', workbench_index_path, class: nav_link_class(workbench_index_path) %>
          <%= link_to 'Datasets', datasets_path, class: nav_link_class(datasets_path) %>
          <%= link_to 'Experiments', experiments_path, class: nav_link_class(experiments_path) %>
        </div>
      </div>
    </nav>

    <main id="main-content">
      <%= yield %>
    </main>
  </body>
</html>
```

**Helper Method** (add to `application_helper.rb`):

```ruby
def nav_link_class(path)
  base = "px-3 py-2 text-sm font-medium transition-colors duration-150"
  active = "bg-amber-600 text-neutral-950 rounded-md"
  inactive = "text-neutral-300 hover:bg-neutral-800 hover:text-white rounded-md"

  request.path.start_with?(path) ? "#{base} #{active}" : "#{base} #{inactive}"
end
```

**Responsive Behavior:**
- **<640px**: Mobile menu hidden, hamburger visible
- **≥640px**: Desktop nav visible, hamburger hidden

---

### 2. experiments/index.html.erb

**Current Issues:**
- Line 2: Uses Tailwind container classes
- Lines 5-10: Button with inline SVG
- Lines 13-41: Table wrapped in Tailwind divs
- Lines 44-58: Empty state uses Tailwind
- Multi-color score system (red/orange/yellow/lime/green)

**Mobile Concerns:**
- Table has 4+ columns - will overflow on 375px
- Empty state padding too large on mobile
- Button with icon needs wrapping on small screens

**Migration:**

```erb
<% content_for :title, 'Experiments' %>

<div class="container py-8">
  <div class="split mb-6">
    <h1 class="text-accent mb-0">Experiments</h1>

    <%= render "leva/shared/button",
      text: "Create New Experiment",
      href: new_experiment_path,
      variant: "primary" %>
  </div>

  <% if @experiments.any? %>
    <%# Responsive table wrapper %>
    <div class="card p-0">
      <div class="table-responsive">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Status</th>
              <th>Total Results</th>
              <% Leva::EvaluationResult.distinct.pluck(:evaluator_class).each do |evaluator_class| %>
                <th><%= evaluator_class %></th>
              <% end %>
              <th class="sr-only">Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= render @experiments %>
          </tbody>
        </table>
      </div>
    </div>
  <% else %>
    <%= render "leva/shared/empty_state",
      icon: '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>',
      title: "No experiments yet",
      description: "Get started by creating a new experiment.",
      button_text: "Create your first experiment",
      button_href: new_experiment_path %>
  <% end %>
</div>
```

**Responsive Behavior:**
- **<640px**: Title stacks above button, table scrolls horizontally
- **640px-768px**: Title and button side-by-side, table still scrollable
- **≥768px**: Full layout, table fits comfortably

---

### 3. experiments/show.html.erb

**Current Issues:**
- Lines 39-46: Multi-color score logic (5 colors)
- Lines 92-99: Duplicate color logic
- Lines 66-115: Wide table (7+ columns)
- No responsive grid for evaluation summary

**Mobile Concerns:**
- Grid should stack on mobile
- Table will definitely overflow
- Score cards need padding reduction
- Auto-refresh meta tag (keep)

**Key Changes:**
1. Replace multi-color scores with **single amber gradient** using score_meter
2. Use `.grid-3` for evaluation summary (stacks on mobile)
3. Wrap runner results table in `.table-responsive`
4. Reduce card padding on mobile

**Migration:**

```erb
<% content_for :title, @experiment.name %>
<% content_for :head do %>
  <% if @experiment.status == 'pending' || @experiment.status == 'running' %>
    <meta http-equiv="refresh" content="5">
  <% end %>
<% end %>

<div class="container py-8">
  <%# Header %>
  <div class="mb-8">
    <div class="split mb-4">
      <div>
        <h1 class="text-accent mb-2"><%= @experiment.name %></h1>
        <p class="text-muted mb-2"><%= @experiment.description %></p>
        <p style="color: var(--amber-400);" aria-live="polite">
          Status: <%= @experiment.status&.capitalize || 'N/A' %>
        </p>
      </div>

      <div class="cluster">
        <% if @experiment.status != 'completed' %>
          <%= render "leva/shared/button",
            text: "Edit Experiment",
            href: edit_experiment_path(@experiment),
            variant: "secondary" %>
        <% end %>

        <%= button_to "Rerun Experiment",
          rerun_experiment_path(@experiment),
          method: :post,
          class: "btn btn-primary",
          data: { confirm: 'Are you sure you want to rerun this experiment? This will delete all existing results.' } %>
      </div>
    </div>
  </div>

  <%# Evaluation Summary %>
  <%= render "leva/shared/card", measure: true do %>
    <h2 style="font-size: 1.875rem; margin-bottom: var(--space-6);">Evaluation Summary</h2>

    <% if @experiment.evaluation_results.any? %>
      <div class="grid grid-3">
        <% @experiment.evaluation_results.group_by(&:evaluator_class).each do |evaluator_class, results| %>
          <div class="card">
            <h3 class="mb-4"><%= evaluator_class %></h3>
            <% avg_score = (results.sum(&:score) / results.size.to_f).round(2) %>

            <%# Use score meter instead of multi-color text %>
            <%= render "leva/shared/score_meter",
              score: avg_score,
              label: "Average Score" %>

            <p class="text-muted mt-4">Evaluations: <%= results.size %></p>
          </div>
        <% end %>
      </div>
    <% else %>
      <p class="text-muted" style="font-size: 1.125rem;">No evaluation results available yet.</p>
    <% end %>
  <% end %>

  <%# Experiment Details %>
  <%= render "leva/shared/card" do %>
    <h2 class="mb-4">Experiment Details</h2>
    <p class="text-muted">
      Dataset: <%= link_to @experiment.dataset.name, dataset_path(@experiment.dataset), style: "color: var(--amber-400);" %>
    </p>
    <p class="text-muted">
      Prompt: <%= @experiment.prompt ? @experiment.prompt.name : 'Not specified' %>
    </p>
  <% end %>

  <%# Runner Results %>
  <%= render "leva/shared/card" do %>
    <h2 class="mb-4">Runner Results</h2>

    <% if @experiment.runner_results.any? %>
      <div class="table-responsive">
        <table>
          <thead>
            <tr>
              <th>Dataset Record</th>
              <th>Prompt</th>
              <th>Prediction</th>
              <th>Ground Truth</th>
              <% @experiment.evaluation_results.group_by(&:evaluator_class).keys.each do |evaluator_class| %>
                <th><%= evaluator_class %></th>
              <% end %>
              <th>Created At</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <% @experiment.runner_results.each do |runner_result| %>
              <tr>
                <td><%= runner_result.dataset_record.display_name %></td>
                <td><%= runner_result.prompt.name %> (v<%= runner_result.prompt_version %>)</td>
                <td class="line-clamp-2"><%= runner_result.prediction %></td>
                <td class="line-clamp-2"><%= runner_result.ground_truth %></td>

                <% @experiment.evaluation_results.group_by(&:evaluator_class).keys.each do |evaluator_class| %>
                  <% eval_result = runner_result.evaluation_results.find_by(evaluator_class: evaluator_class) %>
                  <td>
                    <% if eval_result %>
                      <%# Single amber color, varies by score %>
                      <% score = eval_result.score %>
                      <% score_class = score >= 0.7 ? "score-high" : (score >= 0.4 ? "score-mid" : "score-low") %>
                      <span class="text-mono <%= score_class %>" style="font-weight: 600;">
                        <%= sprintf('%.2f', score) %>
                      </span>
                    <% else %>
                      <span class="text-muted">N/A</span>
                    <% end %>
                  </td>
                <% end %>

                <td class="text-mono" style="font-size: 0.8125rem;">
                  <%= runner_result.created_at.strftime("%Y-%m-%d %H:%M") %>
                </td>
                <td>
                  <div class="cluster gap-2">
                    <%= link_to 'View', experiment_runner_result_path(@experiment, runner_result), style: "color: var(--amber-400);" %>
                    <%= link_to 'Test', workbench_index_path(prompt_id: runner_result.prompt_id, dataset_record_id: runner_result.dataset_record_id, runner: @experiment.runner_class), style: "color: var(--amber-400);" %>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    <% else %>
      <p class="text-muted">No runner results available yet.</p>
    <% end %>
  <% end %>
</div>
```

**Key UX Improvements:**
1. **Score meters** replace multi-color text - cleaner, animated
2. **`.grid-3`** stacks 1 column on mobile, 2 on tablet, 3 on desktop
3. **`.line-clamp-2`** truncates long predictions/ground truth
4. **`.table-responsive`** enables horizontal scroll on mobile
5. **Aria-live region** for status updates (screen reader friendly)

**Responsive Behavior:**
- **<640px**: Single column grid, table scrolls, reduced padding
- **640-1024px**: 2-column grid, table still scrollable
- **≥1024px**: 3-column grid, table fits

---

### 4. workbench/index.html.erb (MOST COMPLEX)

**Current Issues:**
- Line 2: Fixed viewport height layout (`h-[calc(100vh-4rem)]`)
- Line 1 (_prompt_sidebar): Fixed width sidebar (`w-64`)
- No mobile layout - sidebar wastes 33% of screen
- Complex 3-panel layout not responsive

**Mobile Strategy:**
- **<768px**: Stack vertically, collapsible sidebar
- **≥768px**: 2-panel (sidebar + main)
- **≥1024px**: 3-panel (sidebar + content + results)

**Migration:**

```erb
<% content_for :title, 'Workbench' %>

<div class="workbench-layout">
  <%# Mobile: Dropdown selector for prompt %>
  <div class="hidden-desktop px-4 py-4 card" style="border-radius: 0; border-left: 0; border-right: 0; border-top: 0;">
    <label for="mobile-prompt-selector" class="mb-2">Select Prompt:</label>
    <select id="mobile-prompt-selector"
            onchange="window.location.href = '/workbench?prompt_id=' + this.value">
      <option value="">Choose a prompt...</option>
      <% @prompts.each do |prompt| %>
        <option value="<%= prompt.id %>" <%= 'selected' if @selected_prompt&.id == prompt.id %>>
          <%= prompt.name %>
        </option>
      <% end %>
    </select>
  </div>

  <div class="workbench-grid">
    <%# Desktop: Sidebar (hidden on mobile) %>
    <aside class="workbench-sidebar hidden-mobile">
      <%= render 'prompt_sidebar', prompts: @prompts, selected_prompt: @selected_prompt %>
    </aside>

    <%# Main content area %>
    <div class="workbench-main">
      <%= render 'top_bar', selected_prompt: @selected_prompt %>
      <div class="workbench-content">
        <%= render 'prompt_content', selected_prompt: @selected_prompt %>
        <div class="workbench-results">
          <%= render 'results_section', evaluators: @evaluators, dataset_record: @dataset_record %>
        </div>
      </div>
    </div>
  </div>
</div>

<style>
  .workbench-layout {
    display: flex;
    flex-direction: column;
    min-height: calc(100vh - 4rem);
  }

  .workbench-grid {
    display: flex;
    flex: 1;
    overflow: hidden;
  }

  .workbench-sidebar {
    width: 16rem;
    background: var(--neutral-900);
    border-right: 1px solid var(--neutral-800);
    overflow-y: auto;
  }

  .workbench-main {
    flex: 1;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .workbench-content {
    flex: 1;
    display: flex;
    overflow: hidden;
  }

  .workbench-results {
    width: 100%;
    overflow-y: auto;
  }

  /* Tablet/Desktop: Side-by-side content + results */
  @media (min-width: 1024px) {
    .workbench-content {
      flex-direction: row;
    }

    .workbench-results {
      width: 50%;
      border-left: 1px solid var(--neutral-800);
    }
  }
</style>
```

**Responsive Behavior:**
- **<768px**: Dropdown selector, single panel, no sidebar
- **768-1024px**: Sidebar + stacked content
- **≥1024px**: Sidebar + content + results (3-panel)

---

## Common Patterns Across All Views

### 1. Score Visualization

**OLD** (Multi-color):
```erb
<% color_class = case score
   when 0...0.2 then 'text-red-500'
   when 0.2...0.4 then 'text-orange-500'
   when 0.4...0.6 then 'text-yellow-500'
   when 0.6...0.8 then 'text-lime-500'
   else 'text-green-400'
   end %>
<span class="<%= color_class %>"><%= score %></span>
```

**NEW** (Amber gradient):
```erb
<%= render "leva/shared/score_meter", score: score, label: "Score" %>
```

**OR for inline:**
```erb
<% score_class = score >= 0.7 ? "score-high" : (score >= 0.4 ? "score-mid" : "score-low") %>
<span class="text-mono <%= score_class %>"><%= sprintf('%.2f', score) %></span>
```

### 2. Responsive Tables

**Always wrap in:**
```erb
<div class="card p-0">
  <div class="table-responsive">
    <table>...</table>
  </div>
</div>
```

### 3. Responsive Grids

**2-column:**
```erb
<div class="grid grid-2">
  <div class="card">...</div>
  <div class="card">...</div>
</div>
```

**3-column:**
```erb
<div class="grid grid-3">
  <div class="card">...</div>
  <div class="card">...</div>
  <div class="card">...</div>
</div>
```

Grids automatically stack on mobile!

### 4. Truncate Long Text

**In tables:**
```erb
<td class="line-clamp-2"><%= long_text %></td>
```

**Elsewhere:**
```erb
<p class="text-truncate"><%= long_text %></p>
```

### 5. Mobile Padding

**Cards:**
```erb
<%= render "leva/shared/card" do %>
  <%# Automatically responsive - p-12 becomes p-6 on mobile %>
<% end %>
```

### 6. Split Layouts (Title + Action)

```erb
<div class="split mb-6">
  <h1 class="mb-0">Title</h1>
  <%= render "leva/shared/button", ... %>
</div>
```

Automatically stacks on mobile!

---

## Testing Checklist

### Mobile (375px)
- [ ] Navigation: Hamburger menu works, links accessible
- [ ] All tables scroll horizontally
- [ ] Buttons don't overflow
- [ ] Text scales appropriately
- [ ] Forms are usable
- [ ] Workbench uses dropdown selector

### Tablet (768px)
- [ ] Navigation: Desktop nav visible
- [ ] Grids show 2 columns
- [ ] Tables fit better but may still scroll
- [ ] Workbench shows sidebar
- [ ] Touch targets ≥44px

### Desktop (1280px+)
- [ ] Full 3-column grids
- [ ] All tables fit without scrolling
- [ ] Workbench shows all 3 panels
- [ ] Optimal spacing and typography

### Accessibility
- [ ] Skip link works
- [ ] All forms have labels
- [ ] Score meters have aria attributes
- [ ] Focus visible on all interactive elements
- [ ] Color contrast ≥4.5:1
- [ ] Screen reader announces status changes

### Performance
- [ ] CSS file <50kb
- [ ] No layout shift
- [ ] Smooth animations (respects prefers-reduced-motion)

---

## Next Steps

1. **Migrate layout** (application.html.erb) - PRIORITY 1
2. **Test navigation** on mobile/tablet/desktop
3. **Migrate index pages** (experiments, datasets) - PRIORITY 2
4. **Migrate detail pages** (show views) - PRIORITY 3
5. **Migrate forms** - PRIORITY 4
6. **Migrate workbench** (most complex) - PRIORITY 5
7. **Full responsive testing** - PRIORITY 6
8. **Accessibility audit** - PRIORITY 7

---

## Design System Assets

**Available Partials:**
- `leva/shared/_button.html.erb`
- `leva/shared/_card.html.erb`
- `leva/shared/_score_meter.html.erb`
- `leva/shared/_empty_state.html.erb`
- `leva/shared/_alert.html.erb`

**CSS File:**
- `app/assets/stylesheets/leva/application.css` (745 lines, fully responsive)

**Documentation:**
- `docs/DESIGN_SYSTEM.md` - Component usage guide
- `docs/MIGRATION_PLAN.md` - This file

---

**STATUS**: Ready to begin Phase 2 (Layout Migration) 🚀
