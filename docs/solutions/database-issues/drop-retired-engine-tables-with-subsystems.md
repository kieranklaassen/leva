---
title: Drop Retired Rails Engine Tables With Their Subsystems
date: 2026-06-02
category: database-issues
module: leva
problem_type: database_issue
component: database
symptoms:
  - "Dataset deletion can fail after a subsystem model association is removed while its foreign-keyed table remains."
root_cause: missing_workflow_step
resolution_type: migration
severity: medium
tags: [rails-engine, migrations, foreign-keys, subsystem-removal]
---

# Drop Retired Rails Engine Tables With Their Subsystems

## Problem

Removing a Rails engine subsystem requires more than deleting its Ruby classes, routes, views, and dependencies. A retired table can retain foreign keys into active tables after its model association is gone.

For example, removing prompt optimization code while leaving `leva_optimization_runs` in place leaves a foreign key to `leva_datasets`. Historical optimization rows can then block dataset deletion even though the application no longer exposes a way to manage those rows.

## Symptoms

- Deleting an active parent record can fail because an unused child table still references it.
- Fresh installations retain schema and constraints for a feature that no longer exists.
- Runtime reference searches look clean even though the database contract is incomplete.

## What Didn't Work

Deleting the subsystem's Ruby code and dependency chain was necessary but insufficient. Preserving the historical create migration is also necessary for migration history, but that migration alone leaves fresh databases with the retired table.

## Solution

1. Preserve the historical create migration.
2. Add a new reversible migration that drops the retired table.
3. Include the table definition in the `drop_table` block so schema rollback can recreate the table.
4. Update the dummy application schema.
5. Verify migration forward, rollback, reapply, and scratch-database paths.

```ruby
class DropLevaOptimizationRuns < ActiveRecord::Migration[7.2]
  def change
    drop_table :leva_optimization_runs do |t|
      # Preserve the retired schema definition for rollback.
    end
  end
end
```

This removes the unused storage and its foreign keys from upgraded and newly initialized databases. Rollback recreates the schema, but it does not restore deleted rows. Archive historical data before migration when it must be retained.

## Prevention

When removing a Rails engine subsystem:

- Inventory routes, controllers, jobs, models, services, views, dependencies, documentation, tables, indexes, and foreign keys.
- Keep historical migrations intact and add a cleanup migration.
- Check the generated schema after migrating.
- Run forward, rollback, reapply, and scratch-database migration checks.
- Note destructive data removal in release notes.

## Related Issues

No related GitHub issues were found.
