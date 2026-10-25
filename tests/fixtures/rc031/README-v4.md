# Genuine RC-031 run-v4 predecessor envelopes

These six files are original local-save envelope bytes from completed RC-031
verification, copied on October 24, 2026 before RC-032 changed the run contract.
No fields or version numbers were rewritten. `origins-v4.json` records each
source and SHA-256 hash. They use the unchanged `rc028_local_v1` envelope and
profile v1.

`ranked-history-v4.json`, `active-reliquary-v4.json` and
`ranked-relic-shop-v4.json` use the excluded `upgrade_relic_route_fixture.gd`
history context. They retain real battles, individual UID upgrades, relic
acquisition, chronological HP/maxHP/Gold, shop policy/stock/receipts and
resolved or pending services.

`interrupted-entry-v4.json`, `pending-reward-v4.json` and
`pending-defeat-v4.json` use `reward_route_fixture.gd`. They retain exact
entry replay/random streams, genuine pending battle/reward state and a
committed defeat. The interrupted entry also retains intentionally large
allocator/generation values from the earlier integer-encoding campaign.

These are excluded migration evidence, not replacement production saves.
