DFLAGS_UNITTEST := -unittest
DFLAGS_DEBUG := -debug
DFLAGS_RELEASE := -O -release -boundscheck=off

ifeq ($(DEBUG),1)
	DFLAGS := $(DFLAGS_DEBUG)
else

ifeq ($(RELEASE), 1)
	DFLAGS := $(DFLAGS_RELEASE)
else
	DFLAGS := $(DFLAGS_UNITTEST)
endif
endif

BUILDDIR := build

$(BUILDDIR)/fftlut: fftLutComparison.d
	@dmd $(DFLAGS) $^ -of$@

$(BUILDDIR)/fftbench: fftBenchmark.d
	@dmd $(DFLAGS) $^ -of$@

$(BUILDDIR)/random: random.d region.d
	@dmd $(DFLAGS) -main $^ -of$@

clean:
	-@$(RM) $(wildcard $(BUILDDIR)/*)

.PHONY: clean
