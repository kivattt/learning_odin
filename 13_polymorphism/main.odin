package main

import "core:fmt"

add :: proc($A, $B: $I, $T: typeid) -> T {
	return A + B
}

main :: proc() {
	fmt.println(add(5, 10, int))
	fmt.println(add(5.0, 10.1, f64))
}
