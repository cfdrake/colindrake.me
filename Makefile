DEST=build

.PHONY: build clean dev

build:
	hugo -d $(DEST)
clean:
	rm -rf $(DEST)
dev:
	hugo server
