vlib work
vlog AHB_LITE_SLAVE.v AHB_LITE_SLAVE_TB.v
vsim -voptargs=+acc work.AHB_LITE_SLAVE_TB -l SLAVE.log
add wave *
run -all
