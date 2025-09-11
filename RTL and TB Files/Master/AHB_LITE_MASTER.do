vlib work
vlog AHB_LITE_MASTER.v AHB_LITE_MASTER_TB.v
vsim -voptargs=+acc work.AHB_LITE_MASTER_TB -l MASTER.log
add wave *
run -all
