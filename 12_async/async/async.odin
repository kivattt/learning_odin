package async

import "core:thread"
import "core:sync"

Async :: struct {
	thread: ^thread.Thread,
	inputData: $T,

	ptr: rawptr,
	ptrMutex: sync.Mutex,

	running: atomic.
}

go :: proc(async: ^Async) {
	async.thread = thread.create_and_start_with_data(
		&threadData,
		proc(raw: rawptr) {
			threadData := transmute(^ThreadData)raw

			//time.sleep(10000 * time.Nanosecond)
			sync.mutex_lock(threadData.ptrMutex)

			data := new(Data)
			data.text = "Hello, world!"
			threadData.ptr^ = data
			sync.mutex_unlock(threadData.ptrMutex)
		}
	)
}

fini :: proc() {
	thread.join(t)
}
