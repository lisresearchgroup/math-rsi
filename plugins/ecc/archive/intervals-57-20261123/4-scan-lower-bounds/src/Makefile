# layers3 build. Static, portable x86-64-v2 (no -march=native: Cluster CPU model unknown).
CC      ?= gcc
CFLAGS  = -O3 -march=x86-64-v2 -mpopcnt -static -pthread -Wall -Wextra -Wno-unused-parameter -Wno-format-truncation
BIN     = ../bin

all: $(BIN)/layers3 ../qual/ref/layers2

$(BIN)/layers3: layers3.c
	mkdir -p $(BIN)
	$(CC) $(CFLAGS) -o $@ layers3.c

# unmodified layers2 kept for comparison (qualification item 3)
../qual/ref/layers2: layers2.c
	mkdir -p ../qual/ref
	$(CC) -O3 -march=x86-64-v2 -mpopcnt -o $@ layers2.c

clean:
	rm -f $(BIN)/layers3 ../qual/ref/layers2

.PHONY: all clean
