PYTHON="<python-binary>"
BASH=/usr/bin/bash
UNAME=$(shell uname)

ifeq ($(UNAME), Darwin)
	PYTHON=python3
endif


## ------------------ docs ------------------ ##
docs-serve:
	cd docs/_build/html && python -m http.server 9091

docs-build:
	make -C docs/ html

docs-clean:
	make -C docs/ clean
## ------------------------------------------ ##

## ------------------ sync ------------------ ##
sync:	
	$(BASH) autoconf/sync.sh
## ------------------------------------------ ##

## ----------------- themes ----------------- ##
gen-tone4:
	$(PYTHON) autoconf/gen_theme.py -a kitty -p tone4

set-tone4-light:
	$(PYTHON) autoconf/set_theme.py -p tone4 -s light -a "*"

set-tone4-dark:
	$(PYTHON) autoconf/set_theme.py -p tone4 -s dark -a "*"
## ------------------------------------------ ##
