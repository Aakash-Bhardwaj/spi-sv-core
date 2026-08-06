.PHONY: help sim synth synth_sky130 timing clean all

help:
	@echo "SPI SV Core"
	@echo ""
	@echo "Available targets:"
	@echo "  sim           Run simulation"
	@echo "  synth         Run generic synthesis"
	@echo "  synth_sky130  Run Sky130 technology-mapped synthesis"
	@echo "  timing        Run OpenSTA timing analysis"
	@echo "  clean         Remove generated files"
	@echo "  all           Run simulation, synthesis, and timing analysis"

sim:
	mkdir -p sim
	iverilog -g2012 -o sim/spi rtl/*.sv assertions/*.sv tb/tb_spi_top.sv
	vvp sim/spi

synth:
	mkdir -p reports/synthesis
	yosys -s scripts/synth_spi_top.ys | tee reports/synthesis/generic_synthesis_report.txt

synth_sky130:
	mkdir -p reports/synthesis
	yosys -s scripts/synth_sky130.ys | tee reports/synthesis/sky130_synthesis_report.txt

timing:
	mkdir -p reports/timing
	sta scripts/timing_spi.tcl | tee reports/timing/opensta_report.txt

clean:
	rm -f simv
	rm -f *.vcd

all: sim synth synth_sky130 timing