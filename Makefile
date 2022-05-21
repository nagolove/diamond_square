# GNU Make workspace makefile autogenerated by Premake

ifndef config
  config=debug
endif

ifndef verbose
  SILENT = @
endif

ifeq ($(config),debug)
  wrp_config = debug
endif
ifeq ($(config),release)
  wrp_config = release
endif

PROJECTS := wrp

.PHONY: all clean help $(PROJECTS) 

all: $(PROJECTS)

wrp:
ifneq (,$(wrp_config))
	@echo "==== Building wrp ($(wrp_config)) ===="
	@${MAKE} --no-print-directory -C . -f wrp.make config=$(wrp_config)
endif

clean:
	@${MAKE} --no-print-directory -C . -f wrp.make clean

help:
	@echo "Usage: make [config=name] [target]"
	@echo ""
	@echo "CONFIGURATIONS:"
	@echo "  debug"
	@echo "  release"
	@echo ""
	@echo "TARGETS:"
	@echo "   all (default)"
	@echo "   clean"
	@echo "   wrp"
	@echo ""
	@echo "For more information, see https://github.com/premake/premake-core/wiki"