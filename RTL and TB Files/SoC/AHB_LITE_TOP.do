vlib work
vlog *.v
vsim -voptargs=+acc work.AHB_LITE_TOP_TB -l TOP.log
add wave *
run -all
