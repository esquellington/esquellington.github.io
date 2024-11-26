# Makefile to call Emacs publish.el from commandline

.PHONY: all publish

all: publish

publish: publish.el
	@echo "Publishing..."
	emacs -Q --script publish.el

clean:
	@echo "Cleaning..."
	@rm -rvf public
