package main

import "core:fmt"
import "core:sync"
import "core:thread"
import "core:time"

Data :: struct {
	text: string,
}

ThreadData :: struct {
	ptr: ^^Data,
	ptrMutex: ^sync.Mutex,
}

main :: proc() {
	ptr: ^Data = nil
	ptrMutex: sync.Mutex

	threadData := ThreadData{
		ptr = &ptr,
		ptrMutex = &ptrMutex,
	}

	thread := thread.create_and_start_with_data(
		&threadData,
		proc(raw: rawptr) {
			threadData := transmute(^ThreadData)raw

			time.sleep(5 * time.Second)
			sync.mutex_lock(threadData.ptrMutex)

			data := new(Data)
			data.text = "Hello, world!"
			threadData.ptr^ = data
			sync.mutex_unlock(threadData.ptrMutex)
		}
	)

	for {
		time.sleep(333 * time.Millisecond)
		
		sync.mutex_lock(&ptrMutex)
		if ptr == nil {
			sync.mutex_unlock(&ptrMutex)
			fmt.println("nothing...")
			continue
		}

		fmt.println("found:", ptr.text)

		sync.mutex_unlock(&ptrMutex)
	}
}
