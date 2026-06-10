.PRECIOUS: %.cpc

%.cpc : %.smt2
	@./cvc5portfolio $<

%.proof : %.cpc
	@echo $< >$@
	@ethos $< >>$@
	@cat $@
