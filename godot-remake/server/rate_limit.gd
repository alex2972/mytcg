class_name RateLimiter
extends RefCounted
## Token bucket per key (peer id): `rate` tokens per second, at most `burst` stored.

var rate := 30.0
var burst := 60.0
var _buckets := {}        ## key -> [tokens, last_time]

func _init(per_second := 30.0, max_burst := 60.0) -> void:
	rate = per_second
	burst = max_burst

## Spends one token for `key` at time `now`; false when the bucket is empty.
func allow(key, now: float) -> bool:
	var b: Array = _buckets.get(key, [burst, now])
	var tokens: float = minf(burst, float(b[0]) + (now - float(b[1])) * rate)
	if tokens < 1.0:
		_buckets[key] = [tokens, now]
		return false
	_buckets[key] = [tokens - 1.0, now]
	return true

func forget(key) -> void:
	_buckets.erase(key)
