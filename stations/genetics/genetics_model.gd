extends RefCounted
## Mendel'in tek karakter kalıtımı: her Punnett hücresi eşit olasılıktadır.
## Gerçek dört yavrunun mutlaka bu dağılımda olması beklenmez.


static func gametes(genotype: String) -> PackedStringArray:
	match genotype:
		"AA": return PackedStringArray(["A", "A"])
		"Aa": return PackedStringArray(["A", "a"])
		"aa": return PackedStringArray(["a", "a"])
	return PackedStringArray()


static func cross(first: String, second: String) -> PackedStringArray:
	var left := gametes(first)
	var right := gametes(second)
	var results := PackedStringArray()
	if left.size() != 2 or right.size() != 2:
		return results
	for a in left:
		for b in right:
			if a == "A" and b == "A":
				results.append("AA")
			elif a == "a" and b == "a":
				results.append("aa")
			else:
				results.append("Aa")
	return results


static func recessive_probability(first: String, second: String) -> float:
	var children := cross(first, second)
	if children.is_empty():
		return NAN
	var count := 0
	for child in children:
		if child == "aa":
			count += 1
	return float(count) / float(children.size())
