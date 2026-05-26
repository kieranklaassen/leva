# frozen_string_literal: true

# An {EmailSample} whose label teaches BOTH the category AND the inbox/briefed
# routing decision (Cora's "should this be briefed or not?" path) in one shot.
#
# `ground_truth` is a compact JSON object: {"category": "...", "routing": "..."}
# where routing is one of inbox | briefed | archived.
#
# Seeded by `script/datasets/seed_routing_dataset.rb`.
class EmailRoutingSample < EmailSample
  # @return [String] JSON label combining category + routing decision
  def ground_truth
    { category: category, routing: routing }.to_json
  end
end
