DFLAGS_UNITTEST := -unittest
DFLAGS_DEBUG := -debug
DFLAGS_RELEASE := -O -release -boundscheck=off

ifeq ($(DEBUG),1)
	DFLAGS := $(DFLAGS_DEBUG)
else
	DFLAGS := $(DFLAGS_UNITTEST)
endif

BUILDDIR := build

$(BUILDDIR)/random: random.d region.d
	@dmd $(DFLAGS) -main $^ -of$@

clean:
	-@$(RM) $(wildcard $(BUILDDIR)/*)

.PHONY: clean
