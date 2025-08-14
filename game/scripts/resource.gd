extends Node2D

var amount := 500

func mined(rate: float) -> int:
	if amount <= 0:
		return 0
	var mined_amount = int(min(rate, amount))
	amount -= mined_amount
	if amount <= 0:
		queue_free()
	return mined_amount
