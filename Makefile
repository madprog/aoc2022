ASFLAGS=-g -O0 -ansi -pedantic-errors -Wall -Werror

EXECUTABLES=$(shell find . -iname \*.s | sed s/.s$$//)

all: ${EXECUTABLES}

clean:
	rm -f ${EXECUTABLES}
