#!/bin/bash
set -e

RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

rm -rf $BASEDIR/sim/xsim/output/*

if [ ! -d "$BASEDIR/sim/xsim/work" ]; then
  mkdir $BASEDIR/sim/xsim/work
fi

rm -rf $BASEDIR/sim/xsim/work/*

cd $BASEDIR/sim/xsim/work

start=`date +%s`

$XVLOG --sv \
            $BASEDIR/verilog/conf/configure.sv \
            $BASEDIR/verilog/rtl/constants.sv \
            $BASEDIR/verilog/rtl/wires.sv \
            $BASEDIR/verilog/rtl/functions.sv \
            $BASEDIR/verilog/rtl/bit_alu.sv \
            $BASEDIR/verilog/rtl/bit_clmul.sv \
            $BASEDIR/verilog/rtl/btac.sv \
            $BASEDIR/verilog/rtl/alu.sv \
            $BASEDIR/verilog/rtl/agu.sv \
            $BASEDIR/verilog/rtl/bcu.sv \
            $BASEDIR/verilog/rtl/lsu.sv \
            $BASEDIR/verilog/rtl/csr_alu.sv \
            $BASEDIR/verilog/rtl/mul.sv \
            $BASEDIR/verilog/rtl/div.sv \
            $BASEDIR/verilog/rtl/compress.sv \
            $BASEDIR/verilog/rtl/decoder.sv \
            $BASEDIR/verilog/rtl/register.sv \
            $BASEDIR/verilog/rtl/csr.sv \
            $BASEDIR/verilog/rtl/buffer.sv \
            $BASEDIR/verilog/rtl/ifetch.sv \
            $BASEDIR/verilog/rtl/idecode.sv \
            $BASEDIR/verilog/rtl/arbiter.sv \
            $BASEDIR/verilog/rtl/bridge.sv \
            $BASEDIR/verilog/rtl/bus.sv \
            $BASEDIR/verilog/rtl/cdc.sv \
            $BASEDIR/verilog/rtl/clint.sv \
            $BASEDIR/verilog/rtl/tim.sv \
            $BASEDIR/verilog/rtl/rom.sv \
            $BASEDIR/verilog/rtl/ram.sv \
            $BASEDIR/verilog/rtl/spi.sv \
            $BASEDIR/verilog/rtl/uart_rx.sv \
            $BASEDIR/verilog/rtl/uart_tx.sv \
            $BASEDIR/verilog/rtl/prf.sv \
            $BASEDIR/verilog/rtl/fl.sv \
            $BASEDIR/verilog/rtl/rat.sv \
            $BASEDIR/verilog/rtl/rob.sv \
            $BASEDIR/verilog/rtl/rs_int.sv \
            $BASEDIR/verilog/rtl/rs_mem.sv \
            $BASEDIR/verilog/rtl/rename.sv \
            $BASEDIR/verilog/rtl/eu.sv \
            $BASEDIR/verilog/rtl/msu.sv \
            $BASEDIR/verilog/rtl/commit.sv \
            $BASEDIR/verilog/rtl/cpu.sv \
            $BASEDIR/verilog/rtl/soc.sv \
            $BASEDIR/verilog/tb/testbench.sv

$XELAB -top testbench -snapshot testbench_snapshot

for FILE in $BASEDIR/riscv/*.riscv; do
  BASE="${FILE##*/}"
  NAME="${BASE%.*}"
  if [[ "$NAME" == "$PROGRAM"* ]]; then
    cp $BASEDIR/riscv/$NAME.riscv $BASEDIR/sim/verilator/output/$NAME.riscv
    $RISCV/bin/riscv32-unknown-elf-nm -A $BASEDIR/sim/verilator/output/$NAME.riscv | grep -sw 'tohost' | sed -e 's/.*:\(.*\) D.*/\1/' > $BASEDIR/sim/verilator/output/$NAME.host
    $RISCV/bin/riscv32-unknown-elf-objcopy -O binary $BASEDIR/sim/verilator/output/$NAME.riscv $BASEDIR/sim/verilator/output/$NAME.bin
    $PYTHON $BASEDIR/py/bin2dat.py --input $BASEDIR/sim/verilator/output/$NAME.riscv --address 0x0 --offset 0x100000
    cp $BASEDIR/sim/verilator/output/$NAME.dat ram.dat
    cp $BASEDIR/sim/verilator/output/$NAME.host host.dat
    if [ "$DUMP" = "1" ]
    then
      $XSIM testbench_snapshot -testplusarg "MAXTIME=$MAXTIME" -testplusarg "REGFILE=$BASEDIR/sim/verilator/output/$NAME.reg" -testplusarg "CSRFILE=$BASEDIR/sim/verilator/output/$NAME.csr" -testplusarg "MEMFILE=$BASEDIR/sim/verilator/output/$NAME.mem" -tclbatch $BASEDIR/sim/xsim/run.tcl --wdb $BASEDIR/sim/verilator/output/$NAME.wdb
    else
      $XSIM testbench_snapshot -R -testplusarg "MAXTIME=$MAXTIME"
    fi
  fi
done

end=`date +%s`
echo Execution time was `expr $end - $start` seconds.
