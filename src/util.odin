package game

import "core:fmt"

display_txt_f64 :: proc(val: f64) -> string {
	v := val
	sign := ""
	if v < 0 {
		sign = "-"
		v = -v
	}

	if v >= 10_000_000 {
		n := v / 1_000_000.0
		int_part := int(n)
		dec := int((n - f64(int_part)) * 100.0) // 2 decimals

		return fmt.tprintf("%s%d.%02dMi", sign, int_part, dec)
	}

	if v >= 10_000 {
		n := v / 1_000.0
		int_part := int(n)
		dec := int((n - f64(int_part)) * 100.0) // 2 decimals

		return fmt.tprintf("%s%d.%02dk", sign, int_part, dec)
	}

	return fmt.tprintf("%s%d", sign, int(v))
}
