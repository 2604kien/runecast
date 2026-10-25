These are original RC-030 v3 local-save envelope bytes copied on 2026-10-24, before RC-031 migration. `origins.json` records source paths and SHA-256 hashes. No field was deleted and no version number was changed to manufacture a predecessor.

They cover a production checkpoint, resolved recovery/Tithe/shop history, an interrupted battle after recovery, pending rewards, and active instances of all five service variants. Active services retain the original `rc030_services_v1` policy, including unavailable item choices. The replay and resolved records retain real Wisp battle health.

These fixtures are excluded from resource exports. Migration must preserve all existing service receipts and health boundaries, original shop policy/stock, UIDs, allocator gaps and RNG, while explicitly initializing legacy cards to rank zero and relic ownership to empty.
