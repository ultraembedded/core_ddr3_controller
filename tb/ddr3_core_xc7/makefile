ifeq ($(VIVADO_PATH),)
  ${error VIVADO_PATH needs to be specified (should contain /bin /data folders)}
endif

###############################################################################
# Variables:
###############################################################################
SRC_V       += ../../examples/arty_a7/artix7_pll.v
SRC_V       += ./ddr3.v
SRC_V       += ./testbench.v
SRC_V       += ../../src_v/ddr3_dfi_seq.v
SRC_V       += ../../src_v/ddr3_core.v
SRC_V       += ../../src_v/phy/xc7/ddr3_dfi_phy.v
SRC_V       += $(VIVADO_PATH)/data/verilog/src/glbl.v

###############################################################################
# Rules
###############################################################################
all: run

project.prj:
	@echo "" > $@
	@$(foreach _file,$(SRC_V),echo "verilog work \"$(abspath $(_file)\"") >> $@;)

run.tcl:
	@echo "" > $@
	@echo "run 10ms" >> $@
	@echo "quit" >> $@

elaborate: project.prj
	@xelab -prj project.prj -debug typical -relax -L secureip -L unisims_ver -L unimacro_ver testbench glbl -s top_sim

run: elaborate run.tcl
	@xsim top_sim -t run.tcl

view:
	gtkwave waveform.vcd gtksettings.sav  

clean:
	rm -rf xsim* webtalk* xelab*.* top_sim.wdb project.prj run.tcl *.vcd

