
HAVE_PANDOC := $(shell pandoc -v 2> /dev/null)
ifeq ($(HAVE_PANDOC),)
$(error package "pandoc" not installed. Try "yum install pandoc")
endif

TARGETS = html/Story.html

-include local.mk

all: $(TARGETS)

html/%.html : %.md | html
	pandoc -c custom.css -o $@ $<

clean:
	rm -rf $(TARGETS)
