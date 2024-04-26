SHELL  = /bin/bash

TSDIR   ?= $(CURDIR)/tree-sitter-luadoc
TESTDIR ?= $(CURDIR)/test
BINDIR  ?= $(CURDIR)/bin

all:
	@

dev: $(TSDIR)
$(TSDIR):
	@git clone https://github.com/tree-sitter-grammars/tree-sitter-luadoc
	@printf "\33[1m\33[31mNote\33[22m npm build can take a while" >&2
	@cd $(TSDIR) &&                                        \
		npm --loglevel=info --progress=true install && \
		npx tree-sitter generate

.PHONY: parse-%
parse-%: dev
	@cd $(TSDIR) && npx tree-sitter parse $(TESTDIR)/$(subst parse-,,$@)

clean:
	$(RM) -r *~

distclean: clean
	$(RM) -rf $$(git ls-files --others --ignored --exclude-standard)
