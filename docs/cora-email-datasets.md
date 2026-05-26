# Cora Email Training Datasets

Two seedable Leva datasets for fine-tuning a small open model (via the Together
fine-tune feature) to do Cora's email triage. Grounded in Cora's own category
definitions and classification rules (`~/cora`: `app/models/category/*.rb`,
`test/fixtures/category_templates.yml`, `test/fixtures/classification_rule_templates.yml`)
and its strategy (`~/cora/STRATEGY.md`).

## What Cora does (the why)

> Cora handles your email so you can handle your life. The **inbox** is for what
> needs *you*; the **brief** is for what you should *know* but doesn't need
> immediate action. The guarantee is "nothing missed" — high false-positive
> tolerance, near-zero false-negative tolerance on important mail.

So the core decision Cora makes for every email is two-part:

1. **Category** — what *kind* of email is this? (14 defaults + user categories)
2. **Routing** — does it go to the **inbox**, get **briefed**, or get **archived**?

Routing is derived from the category's Cora action:

| Cora action | Routing | Meaning |
|---|---|---|
| `DraftAction` / `InboxAction` | **inbox** | Needs you now (reply needed, or time-sensitive must-see) |
| `BriefAction` | **briefed** | You should know; summarized in the digest + archived |
| `UnsubscribeAction` | **archived** | Spam — never inbox, never briefed |

## The 14 default categories + routing

| Category | Definition (Cora's `categorization_prompt`) | Routing |
|---|---|---|
| `important_draft` | Requires a response; minimal extra context needed | **inbox** |
| `important_context` | Requires a response; significant context/consideration needed | **inbox** |
| `important_sop` | Requires a response matching a standard operating procedure | **inbox** |
| `timely` | Must see immediately, never drafts: OTP/login codes, today's meeting changes, webinar reminders, URGENT | **inbox** |
| `important_info` | Important information, but no response/action needed | **briefed** |
| `action` | An action/task is required, but no reply to a person | **briefed** |
| `promotion` | Marketing/promotional | **briefed** |
| `newsletter` | Newsletters and informational content | **briefed** |
| `comments` | Comments on docs (Google Docs, Figma, …) | **briefed** |
| `payments` | Receipts, invoices paid, payment confirmations | **briefed** |
| `calendar` | Calendar events, invites, updates | **briefed** |
| `packages` | Shipping/delivery/tracking | **briefed** |
| `other` | Info that needs no response/action and fits nothing else | **briefed** |
| `spam` | Phishing/spam/suspicious | **archived** |

### Example custom (user) categories

Users can create their own categories with their own routing. The corpus includes three:

| Category | Routing | Why |
|---|---|---|
| `travel` | briefed | Flight/hotel confirmations, itineraries — know it, no action |
| `investors` | briefed | Investor updates — informational |
| `clients` | inbox | Direct client emails needing a reply — keep in the inbox |

## The two datasets

Both draw the **same** realistic emails (so they're directly comparable); only the label differs.

### 1. `Cora Email Categorization` — email → category

- Recordable: `EmailSample`
- `to_llm_context`: `{ from, from_name, subject, body }`
- **Ground truth**: the category slug, e.g. `"promotion"`

### 2. `Cora Email Routing (Inbox vs Briefed)` — email → category + routing

- Recordable: `EmailRoutingSample`
- `to_llm_context`: `{ from, from_name, subject, body }`
- **Ground truth**: JSON, e.g. `{"category":"promotion","routing":"briefed"}`

Use (1) to train pure categorization; use (2) to train the full "should this be
briefed?" decision in one shot.

## How the emails are generated

`script/datasets/email_corpus.rb` is a deterministic (seeded) generator that
composes authentic emails from template pools per category, grounded in Cora's
classification signals — e.g. promotions from `noreply@brand.com` with
`% off` subjects, payments from `receipts@stripe.com`, calendar invites from
`calendar-notification@google.com` ("Invitation from Google Calendar"), OTP/login
codes for `timely`, phishing patterns for `spam`. ~1000 emails, balanced across
all categories, ~550 unique subjects.

## Running the scripts

From the Leva repo root (they run against the dummy app):

```bash
cd test/dummy
bin/rails runner ../../script/datasets/seed_category_dataset.rb
bin/rails runner ../../script/datasets/seed_routing_dataset.rb
```

Options (env): `COUNT` (default 1000), `SEED` (default 42), `DATASET_NAME`.
Both scripts are **idempotent** — re-running replaces the prior dataset of the same name.

## Fine-tuning them

Once seeded, open the dataset in Leva and click **Fine-tune Model** (needs
`TOGETHER_API_KEY`), or export training JSONL directly:

```ruby
Leva::JsonlExporter.new(Leva::Dataset.find_by(name: "Cora Email Categorization")).to_jsonl
```

Each line is a chat example: the email in the user turn, the label in the
assistant turn — ready for a Together LoRA fine-tune.

## Portability to the host app (Cora)

These scripts target Leva's dummy app and its `EmailSample` recordable. In a real
host (Cora), point the same `EmailCorpus` generator at the host's email recordable
(anything that implements `Leva::Recordable#to_llm_context` + `#ground_truth`),
or replace synthetic emails with sampled real ones.
