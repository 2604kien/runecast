extends RefCounted
## Registered, provisional RC-036 tuning. Shop rules never enter Combat setup.
const LEGACY_POLICY_ID := "rc029_shop_v1"
const POLICY_ID := "rc031_shop_v2"
const ELIGIBILITY_VERSION := 1
const STOCK_COUNT := 3
const RUNE_PRICE := 30
const REMOVAL_PRICE := 40
const RELIC_PRICE := 60
const UPGRADE_PRICE := 35
const MIN_OWNED := 4
const RNG_SALT := 0x52435348
const INITIAL_IDS := ["spark", "shield", "focus", "conjure"]

static func offerings(eligible: Array, rng: RandomNumberGenerator) -> Array:
	var pool := eligible.duplicate()
	for index in range(mini(STOCK_COUNT, pool.size())):
		if index + 1 < pool.size():
			var other := rng.randi_range(index, pool.size() - 1)
			var held: Variant = pool[index]
			pool[index] = pool[other]
			pool[other] = held
	pool.resize(mini(STOCK_COUNT, pool.size()))
	return pool
