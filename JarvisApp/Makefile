.PHONY: build clean run dev

build:
	./build.sh

clean:
	rm -rf .build
	rm -rf ../Jarvis.app

run: build
	open ../Jarvis.app

dev:
	swift build 2>&1
	.build/debug/JarvisApp
