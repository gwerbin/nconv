NIM = nim
DESTDIR = .
PREFIX = $(HOME)/.local
PREFIX_BIN = $(PREFIX)/bin

.PHONY: all
all: $(DESTDIR)/nconv

.PHONY: demo
demo: $(DESTDIR)/nconv
	$< -fh 0xfe

.PHONY: install
install: all
	install -m 0755 $(DESTDIR)/nconv $(PREFIX_BIN)

$(DESTDIR)/nconv: nconv.nim
	$(NIM) c -d:release -o:$@ $<

$(PREFIX_BIN):
	mkdir -p $@
$(DESTDIR):
	mkdir -p $@
