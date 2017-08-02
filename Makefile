

TARGETS = html/Story.html

all: $(TARGETS)

html:
	mkdir html

html/%.html : %.md | html
	pandoc -c custom.css -o $@ $<

clean:
	rm -rf $(TARGETS)
