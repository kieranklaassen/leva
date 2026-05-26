# frozen_string_literal: true

# EmailCorpus — a deterministic generator of realistic emails for Leva training
# datasets, grounded in Cora's own category definitions and classification
# signals (see app/models/category/*.rb and test/fixtures/classification_rule_templates.yml
# in the Cora repo).
#
# Each generated email is a Hash:
#   { from:, from_name:, subject:, body:, category:, routing: }
#
# `category` is one of Cora's 14 default categories (plus a few example custom
# categories); `routing` is the inbox/briefed/archived decision derived from the
# category's Cora action (BriefAction -> briefed, Inbox/DraftAction -> inbox,
# UnsubscribeAction/spam -> archived).
#
# Templates are COHERENT VARIANTS: each variant pairs a matching sender, subject,
# and body (so you never get "Google Docs <notifications@figma.com>"). Variety
# comes from many variants plus per-email placeholder substitution.
#
# Usage:
#   require_relative "email_corpus"
#   EmailCorpus.generate(total: 1000, seed: 42) # => [{...}, ...]
module EmailCorpus
  # Cora category -> inbox/briefed/archived routing (the "should this be briefed?" path).
  ROUTING = {
    # INBOX — needs you now (reply needed, or time-sensitive must-see)
    "important_draft" => "inbox",
    "important_context" => "inbox",
    "important_sop" => "inbox",
    "timely" => "inbox",
    # BRIEFED — you should know, no immediate action; summarized + archived
    "important_info" => "briefed",
    "action" => "briefed",
    "promotion" => "briefed",
    "newsletter" => "briefed",
    "comments" => "briefed",
    "payments" => "briefed",
    "calendar" => "briefed",
    "packages" => "briefed",
    "other" => "briefed",
    # ARCHIVED — never inbox, never briefed
    "spam" => "archived",
    # Example user/custom categories (with their chosen routing)
    "travel" => "briefed",
    "investors" => "briefed",
    "clients" => "inbox"
  }.freeze

  DEFAULT_CATEGORIES = %w[
    important_draft important_context important_sop timely important_info action
    promotion newsletter comments payments calendar packages other spam
  ].freeze

  CUSTOM_CATEGORIES = %w[travel investors clients].freeze

  # ---- placeholder pools -------------------------------------------------

  FIRST = %w[Alex Sam Jordan Taylor Casey Morgan Riley Jamie Chris Dana Priya Wei Ana Diego Noah Maya Liam Sofia Omar Kenji Lena Marcus Ines Ravi Yuki Tom Sarah Ben Grace].freeze
  LAST  = %w[Chen Patel Garcia Smith Johnson Kim Muller Rossi Okafor Nguyen Silva Hansen Costa Park Adams Brooks Reyes Walsh Ito Khan Lopez Schmidt Novak Singh Tan].freeze
  COMPANIES = %w[Acme Northwind Globex Initech Umbrella Vandelay Stark Massive Aperture Helio Brightwave Meridian].freeze
  CLIENT_COMPANIES = %w[brightlabs.io meridian.co northstar.dev quanta.app harborworks.com lumen.studio].freeze
  RETAIL_BRANDS = %w[Everlane Allbirds Glossier Patagonia Bose Nike Wayfair Casper Bombas Chewy].freeze
  SAAS = %w[Notion Figma Linear Slack GitHub Asana Vercel Datadog Zoom Dropbox Airtable].freeze
  PUBLICATIONS = [ "The Pragmatic Engineer", "Lenny's Newsletter", "Stratechery", "Every", "Platformer", "Money Stuff", "TLDR" ].freeze
  CARRIERS = %w[UPS FedEx USPS DHL].freeze
  AIRLINES = [ "United", "Delta", "American Airlines", "Alaska Airlines", "JetBlue" ].freeze
  HOTELS = [ "Marriott", "Hilton", "Airbnb", "Hyatt", "Kimpton" ].freeze
  VC_FIRMS = [ "Sequoia", "Benchmark", "First Round", "Initialized", "Greylock" ].freeze
  CITIES = %w[Austin Denver Chicago Boston Seattle Portland Toronto London Berlin Lisbon].freeze
  TOPICS = [ "the Q3 roadmap", "the pricing migration", "the new onboarding flow", "the data pipeline", "the partnership", "the launch plan", "hiring", "the budget" ].freeze
  PRODUCTS = [ "the spring collection", "wireless headphones", "running shoes", "your favorite mug", "the new planner" ].freeze
  DOCS = [ "Q3 Planning", "Design Spec v2", "Launch Brief", "2026 Budget", "Onboarding Flow", "API Proposal" ].freeze

  module_function

  # Generate a balanced, shuffled corpus.
  # @param total [Integer] approximate number of emails to return
  # @param seed [Integer] RNG seed for reproducibility
  # @param include_custom [Boolean] include the example custom categories
  # @return [Array<Hash>]
  def generate(total: 1000, seed: 42, include_custom: true)
    rng = Random.new(seed)
    cats = DEFAULT_CATEGORIES + (include_custom ? CUSTOM_CATEGORIES : [])
    per = (total.to_f / cats.size).ceil
    emails = cats.flat_map { |cat| Array.new(per) { build(cat, rng) } }
    emails.shuffle(random: rng).first(total)
  end

  # @return [Hash] one email for the given category (coherent variant + filled placeholders)
  def build(category, rng)
    vars = resolve_vars(rng)
    variant = pick(TEMPLATES.fetch(category), rng)
    {
      from: render(variant[:from], vars),
      from_name: render(variant[:from_name], vars),
      subject: render(variant[:subject], vars),
      body: render(variant[:body], vars),
      category: category,
      routing: ROUTING.fetch(category)
    }
  end

  # @return [Hash] a per-email set of resolved placeholder values
  def resolve_vars(rng)
    person = "#{pick(FIRST, rng)} #{pick(LAST, rng)}"
    sender = "#{pick(FIRST, rng)} #{pick(LAST, rng)}"
    brand = pick(RETAIL_BRANDS, rng)
    saas = pick(SAAS, rng)
    company = pick(COMPANIES, rng)
    pub = pick(PUBLICATIONS, rng)
    carrier = pick(CARRIERS, rng)
    airline = pick(AIRLINES, rng)
    hotel = pick(HOTELS, rng)
    vc = pick(VC_FIRMS, rng)
    {
      person: person,
      person_first: person.split.first,
      person_first_lc: person.split.first.downcase,
      sender: sender,
      sender_first: sender.split.first,
      brand: brand,
      brand_domain: "#{domain(brand)}.com",
      saas: saas,
      saas_domain: "#{saas.downcase}.com",
      company: company,
      company_domain: "#{domain(company)}.com",
      client_domain: pick(CLIENT_COMPANIES, rng),
      pub: pub,
      pub_domain: "#{domain(pub)}.com",
      carrier: carrier,
      carrier_domain: "#{carrier.downcase}.com",
      airline: airline,
      airline_domain: "#{domain(airline)}.com",
      hotel: hotel,
      hotel_domain: "#{domain(hotel)}.com",
      vc: vc,
      vc_domain: "#{domain(vc)}.com",
      city: pick(CITIES, rng),
      city2: pick(CITIES, rng),
      topic: pick(TOPICS, rng),
      product: pick(PRODUCTS, rng),
      doc: pick(DOCS, rng),
      pct: pick([ 10, 15, 20, 25, 30, 40, 50, 60 ], rng),
      amount: format("%.2f", rng.rand(4.0..899.0)),
      code: rng.rand(100_000..999_999),
      order: "#{pick(('A'..'Z').to_a, rng)}#{rng.rand(10_000_000..99_999_999)}",
      tracking: "1Z#{rng.rand(100_000_000_000..999_999_999_999)}",
      invoice: "INV-#{rng.rand(1000..9999)}",
      last4: rng.rand(1000..9999),
      day: pick(%w[Mon Tue Wed Thu Fri], rng),
      time: "#{rng.rand(8..17)}:#{pick(%w[00 15 30 45], rng)}",
      month: pick(%w[January February March April May June], rng),
      qn: rng.rand(1..4),
      url: "https://example.com/#{rng.rand(10_000..99_999)}"
    }
  end

  def domain(name)
    name.downcase.gsub(/[^a-z0-9]/, "")
  end

  def pick(arr, rng)
    arr[rng.rand(arr.size)]
  end

  # Replace %{key} tokens; leaves a literal % (e.g. "20% off") untouched.
  def render(template, vars)
    template.gsub(/%\{(\w+)\}/) { vars[Regexp.last_match(1).to_sym].to_s }
  end

  # ---- coherent templates per category ----------------------------------
  # Each entry is a list of variants; each variant's from/from_name/subject/body
  # are written to agree with each other. Grounded in Cora's classification rules.
  TEMPLATES = {
    # ---------------- BRIEFED ----------------
    "promotion" => [
      { from: "deals@%{brand_domain}", from_name: "%{brand}",
        subject: "%{pct}% off everything — ends tonight",
        body: "Hi there,\n\nFor a limited time, take %{pct}% off %{product}. Use code SAVE%{pct} at checkout.\n\nShop now: %{url}\n\nUnsubscribe anytime." },
      { from: "noreply@%{brand_domain}", from_name: "%{brand} Deals",
        subject: "Flash sale: save %{pct}% on %{product}",
        body: "Don't miss out! %{product} is %{pct}% off this weekend only.\n\nShop the sale: %{url}\n\nYou're receiving this because you subscribed to %{brand} emails." },
      { from: "hello@%{brand_domain}", from_name: "%{brand}",
        subject: "Your exclusive offer inside",
        body: "As a valued customer, here's %{pct}% off your next order of %{product}.\n\nShop now: %{url}" }
    ],
    "newsletter" => [
      { from: "hello@%{pub_domain}", from_name: "%{pub}",
        subject: "%{pub}: what we learned about %{topic}",
        body: "Welcome back to %{pub}.\n\nThis week: we dig into %{topic}, three links worth your time, and a chart that surprised us.\n\nRead online: %{url}\n\nUnsubscribe at the bottom of this email." },
      { from: "%{person_first_lc}@substack.com", from_name: "%{pub} by %{person}",
        subject: "Issue #%{qn}: %{topic}",
        body: "Hi friends,\n\nIn today's issue: %{topic}, plus the five stories I couldn't stop thinking about this week.\n\n— %{person}" },
      { from: "newsletter@%{pub_domain}", from_name: "%{pub}",
        subject: "The weekly digest — %{month}",
        body: "This week in %{pub}: %{topic}, and what it means for the rest of us.\n\nRead the full issue: %{url}" }
    ],
    "payments" => [
      { from: "receipts@stripe.com", from_name: "Stripe",
        subject: "Your receipt from %{saas} #%{invoice}",
        body: "Thanks for your payment.\n\nAmount: $%{amount}\nInvoice: %{invoice}\nCard: charged to card ending %{last4}\nDate: %{month} %{qn}\n\nThis is a receipt for your records — no action needed." },
      { from: "service@paypal.com", from_name: "PayPal",
        subject: "You sent a payment of $%{amount}",
        body: "You sent $%{amount} to %{company}.\n\nTransaction ID: %{order}\n\nThis confirmation is for your records." },
      { from: "billing@%{saas_domain}", from_name: "%{saas} Billing",
        subject: "Receipt for your %{saas} subscription",
        body: "Your subscription to %{saas} renewed.\n\nWe charged $%{amount} to the card ending %{last4}. View your invoice: %{url}" }
    ],
    "packages" => [
      { from: "shipment-tracking@amazon.com", from_name: "Amazon.com",
        subject: "Your package has shipped — order #%{order}",
        body: "Good news — your order #%{order} has shipped.\n\nTracking: %{tracking}\nEstimated delivery: %{day}\n\nTrack your package: %{url}" },
      { from: "order-update@amazon.com", from_name: "Amazon.com",
        subject: "Delivered: your order #%{order}",
        body: "Your package was delivered and left at your front door.\n\nOrder #%{order}, tracking %{tracking}." },
      { from: "tracking@%{carrier_domain}", from_name: "%{carrier}",
        subject: "%{carrier}: your package is out for delivery",
        body: "Your %{carrier} package (tracking %{tracking}) is out for delivery and should arrive %{day}." }
    ],
    "calendar" => [
      { from: "calendar-notification@google.com", from_name: "Google Calendar",
        subject: "Invitation: %{topic} sync @ %{day} %{time}",
        body: "You have been invited to the following event.\n\n%{topic} sync\nWhen: %{day} %{time}\nWhere: Google Meet\nGuests: %{person}, %{sender}\n\nInvitation from Google Calendar. RSVP: %{url}" },
      { from: "calendar-notification@google.com", from_name: "Google Calendar",
        subject: "Accepted: %{topic} review",
        body: "%{person} has accepted your invitation to \"%{topic} review\".\n\nWhen: %{day} %{time}\n\nInvitation from Google Calendar." },
      { from: "no-reply@cal.com", from_name: "Cal.com",
        subject: "New booking: %{topic} with %{person}",
        body: "%{person} booked time with you.\n\n%{topic}\nWhen: %{day} %{time}\n\nManage this booking: %{url}" }
    ],
    "comments" => [
      { from: "comments-noreply@docs.google.com", from_name: "Google Docs",
        subject: "%{person} commented in \"%{doc}\"",
        body: "%{person} commented on \"%{doc}\":\n\n\"Can we tighten this section? I think it'll read better.\"\n\nOpen in Google Docs: %{url}" },
      { from: "no-reply@figma.com", from_name: "Figma",
        subject: "%{person} mentioned you via Figma comments",
        body: "%{person} mentioned you in a comment on \"%{doc}\" via Figma comments:\n\n\"@you what do you think of this spacing?\"\n\nReply in Figma: %{url}" }
    ],
    "action" => [
      { from: "notifications@%{saas_domain}", from_name: "%{saas}",
        subject: "Action required: %{topic}",
        body: "A task needs your attention in %{saas}.\n\nTask: %{topic}\nDue: %{day}\n\nPlease complete it before the deadline. View task: %{url}" },
      { from: "no-reply@%{saas_domain}", from_name: "%{saas} Notifications",
        subject: "Deadline approaching: %{topic} due %{day}",
        body: "Reminder: \"%{topic}\" is due %{day} in %{saas}. This needs an action (not a reply). Open it: %{url}" },
      { from: "notifications@%{saas_domain}", from_name: "%{saas}",
        subject: "You were assigned: %{topic}",
        body: "%{sender} assigned \"%{topic}\" to you in %{saas}. Complete it here: %{url}" }
    ],
    "important_info" => [
      { from: "notifications@%{saas_domain}", from_name: "%{saas}",
        subject: "Important update to our Terms of Service",
        body: "We're writing to let you know about an important update to our Terms of Service, effective %{month} %{qn}.\n\nNo action is needed — this is for your awareness. Read the details: %{url}" },
      { from: "support@%{saas_domain}", from_name: "%{saas}",
        subject: "Service alert: scheduled maintenance %{day}",
        body: "Heads up: %{saas} will undergo scheduled maintenance on %{day} from %{time}. No action is required; some features may be briefly unavailable." },
      { from: "admin@%{company_domain}", from_name: "%{company} Admin",
        subject: "Notice: changes to your %{company} account",
        body: "We've updated your %{company} account as part of a routine policy change. No action is needed; details here: %{url}" }
    ],
    "other" => [
      { from: "%{person_first_lc}@%{company_domain}", from_name: "%{person}",
        subject: "Fwd: %{topic}",
        body: "Just forwarding this along for your awareness — no action needed.\n\n%{topic} is moving ahead as planned.\n\n%{person}" },
      { from: "info@%{company_domain}", from_name: "%{company}",
        subject: "FYI: %{topic}",
        body: "Sharing for visibility — nothing for you to do here. %{topic} update attached." },
      { from: "noreply@%{company_domain}", from_name: "%{company}",
        subject: "Re: %{topic}",
        body: "Thanks, all noted. No further action needed on %{topic}." }
    ],
    # ---------------- INBOX ----------------
    "important_draft" => [
      { from: "%{person_first_lc}@%{company_domain}", from_name: "%{person}",
        subject: "Quick question about %{topic}",
        body: "Hi %{sender_first},\n\nCould you send me the latest %{doc} when you get a chance? I need it for %{topic}.\n\nThanks,\n%{person}" },
      { from: "%{person_first_lc}@%{client_domain}", from_name: "%{person}",
        subject: "Can you confirm %{topic}?",
        body: "Hey,\n\nCan you confirm whether we're still on for %{topic}? Just need a quick yes/no.\n\nBest,\n%{person}" },
      { from: "%{person_first_lc}@%{company_domain}", from_name: "%{person}",
        subject: "Request: your input on %{topic}",
        body: "Hi %{sender_first},\n\nWould you mind sharing your input on %{topic}? A couple of lines is plenty.\n\nThanks,\n%{person}" }
    ],
    "important_context" => [
      { from: "%{person_first_lc}@%{company_domain}", from_name: "%{person}",
        subject: "Re: %{topic} proposal",
        body: "Hi %{sender_first},\n\nI've been thinking through %{topic} and wanted your detailed take before we commit. There's real nuance — the analysis suggests two paths, each with tradeoffs, and I'd value your consideration on which fits our goals.\n\nCan we find time to go deep on this?\n\n%{person}" },
      { from: "%{person_first_lc}@%{client_domain}", from_name: "%{person}",
        subject: "Your thoughts on the %{doc}?",
        body: "Following up on %{topic}. This needs careful review — I've attached the detailed analysis. Before I reply to the client, I'd like your thoughts on the approach and the risks.\n\n%{person}" },
      { from: "%{person_first_lc}@%{company_domain}", from_name: "%{person}",
        subject: "Planning for %{topic} — need your read",
        body: "We're planning %{topic} and there are a few complex decisions ahead. I'd love a thoughtful review of the options before our meeting.\n\n%{person}" }
    ],
    "important_sop" => [
      { from: "hr@%{company_domain}", from_name: "%{company} HR",
        subject: "Process: complete your %{month} expense report",
        body: "Per our standard process, please submit your %{month} expense report by %{day}. Reply to confirm once done.\n\nThanks,\n%{company} HR" },
      { from: "support@%{company_domain}", from_name: "%{company} Support",
        subject: "Standard process: approve %{person}'s request",
        body: "Following our standard procedure, please approve %{person}'s access request and reply to confirm. The steps are in the handbook." },
      { from: "procedures@%{company_domain}", from_name: "%{company}",
        subject: "SOP: submit your quarterly review",
        body: "As part of the standard quarterly process, please complete and reply with your review by %{day}." }
    ],
    "timely" => [
      { from: "security@%{saas_domain}", from_name: "%{saas} Security",
        subject: "Your %{saas} verification code is %{code}",
        body: "Your one-time verification code is %{code}. It expires in 10 minutes. If you didn't request this, you can ignore this email." },
      { from: "no-reply@%{saas_domain}", from_name: "%{saas}",
        subject: "%{code} is your login code",
        body: "Use code %{code} to sign in to %{saas}. This code expires in 10 minutes." },
      { from: "calendar-notification@google.com", from_name: "Google Calendar",
        subject: "Reminder: %{topic} starts in 15 minutes",
        body: "This is a reminder that \"%{topic}\" starts at %{time} today. Join here: %{url}" }
    ],
    # ---------------- ARCHIVED ----------------
    "spam" => [
      { from: "security@secure-%{company_domain}", from_name: "Account Security",
        subject: "Your account has been locked — verify within 24 hours",
        body: "Your account has been temporarily suspended. To restore access, verify your identity within 24 hours by clicking here: %{url}\n\nEnter your password to confirm. Failure to act will result in permanent deletion." },
      { from: "no.reply@account-verify-%{brand_domain}", from_name: "%{brand} Support",
        subject: "You've won a $1000 gift card! Claim within 24 hours",
        body: "Congratulations! You've been selected to win a $1000 gift card. Claim your prize now: %{url}\n\nAct now — this offer expires today." },
      { from: "billing@verify-%{company_domain}", from_name: "Billing Team",
        subject: "Confirm your payment details to avoid suspension",
        body: "We could not process your payment. Confirm your credentials and bank account number here to avoid account suspension: %{url}" }
    ],
    # ---------------- CUSTOM ----------------
    "travel" => [
      { from: "confirmations@%{airline_domain}", from_name: "%{airline}",
        subject: "Your flight confirmation — %{city} to %{city2}",
        body: "Your trip is booked.\n\n%{airline} — %{city} (%{day} %{time}) to %{city2}\nConfirmation: %{order}\n\nThis is for your records. Manage your booking: %{url}" },
      { from: "no-reply@%{hotel_domain}", from_name: "%{hotel}",
        subject: "Your %{hotel} booking in %{city2} is confirmed",
        body: "Your reservation at %{hotel} in %{city2} is confirmed.\n\nCheck-in: %{day}\nConfirmation: %{order}\n\nNo action needed." },
      { from: "no-reply@%{airline_domain}", from_name: "%{airline}",
        subject: "Check-in is open for your %{airline} flight to %{city2}",
        body: "Check-in is now open for your flight to %{city2} on %{day}. Confirmation: %{order}. Check in online: %{url}" }
    ],
    "investors" => [
      { from: "updates@%{company_domain}", from_name: "%{company}",
        subject: "%{company} investor update — %{month}",
        body: "Hi investors,\n\nQuick %{month} update:\n- Revenue up %{pct}% MoM\n- Closed %{qn} new enterprise logos\n- Hiring 2 engineers\n\nNo asks this month — just keeping you posted. Full deck: %{url}\n\n%{sender}" },
      { from: "%{person_first_lc}@%{company_domain}", from_name: "%{person}",
        subject: "Q%{qn} update from %{company}",
        body: "Q%{qn} highlights from %{company}: strong retention, $%{amount}k new ARR, and the launch is on track for %{month}. Details attached.\n\n%{person}" },
      { from: "%{person_first_lc}@%{vc_domain}", from_name: "%{person} (%{vc})",
        subject: "Portfolio note: %{company} hits a milestone",
        body: "Sharing a milestone from %{company} in our portfolio — strong quarter. More in the deck: %{url}\n\n%{person}, %{vc}" }
    ],
    "clients" => [
      { from: "%{person_first_lc}@%{client_domain}", from_name: "%{person}",
        subject: "Following up on %{topic}",
        body: "Hi %{sender_first},\n\nFollowing up on %{topic} — could you send over the %{doc} by end of day? Our team is waiting on it to move forward.\n\nThanks,\n%{person}" },
      { from: "%{person_first_lc}@%{client_domain}", from_name: "%{person}",
        subject: "Question about the %{doc}",
        body: "Hey %{sender_first},\n\nQuick one: can you clarify the timeline on %{topic}? I need to update my stakeholders today.\n\nBest,\n%{person}" },
      { from: "%{person_first_lc}@%{client_domain}", from_name: "%{person}",
        subject: "Can we hop on a call about %{topic}?",
        body: "Hi %{sender_first}, would you have 15 minutes tomorrow to discuss %{topic}? A few things I'd like to align on before we proceed.\n\n%{person}" }
    ]
  }.freeze
end
