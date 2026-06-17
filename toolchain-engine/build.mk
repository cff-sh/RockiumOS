ODIN := odin
SRC := ./source
BIN := bin/toolchain-engine

.PHONY: build run debug clean

build:
	mkdir -p bin
	$(ODIN) build $(SRC) -out:$(BIN)

run:
	$(ODIN) run $(SRC)

debug:
	mkdir -p bin
	$(ODIN) build $(SRC) -debug -out:$(BIN)

clean:
	rm -rf bin
