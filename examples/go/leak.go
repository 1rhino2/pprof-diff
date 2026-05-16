package main

import (
	"os"
	"runtime"
	"runtime/pprof"
)

var leaky [][]byte

func allocLeaky(n int) {
	for i := 0; i < n; i++ {
		leaky = append(leaky, make([]byte, 1024))
	}
}

func main() {
	allocLeaky(10)
	f, err := os.Create("before.prof")
	if err != nil {
		panic(err)
	}
	runtime.GC()
	if err := pprof.WriteHeapProfile(f); err != nil {
		panic(err)
	}
	f.Close()

	allocLeaky(30)
	f2, err := os.Create("after.prof")
	if err != nil {
		panic(err)
	}
	runtime.GC()
	if err := pprof.WriteHeapProfile(f2); err != nil {
		panic(err)
	}
	f2.Close()
}
