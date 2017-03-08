
OBJS := $(patsubst %.dot,%.png,$(wildcard *.dot))

all : $(OBJS)
	eog $(OBJS)

%.png : %.dot
	dot -Tpng -o $@ $<

clean:
	rm -f $(OBJS)


