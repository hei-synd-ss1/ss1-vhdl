onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color White /directionmotorregisters_tb/clock
add wave -noupdate -color White /directionmotorregisters_tb/reset
add wave -noupdate -color Gray60 /directionmotorregisters_tb/I_tester/testInfo
add wave -noupdate -color {Violet Red} -radix unsigned /kart/DMOT_CMD_CLOCKS_STEP
add wave -noupdate -color {Violet Red} -radix unsigned /kart/DMOT_MAXCMD_CLOCKS
add wave -noupdate -color {Violet Red} -radix unsigned /kart/DMOT_MINCMD_CLOCKS
add wave -noupdate -divider Rx
add wave -noupdate -color Yellow -radix binary /directionmotorregisters_tb/addressIn
add wave -noupdate -color Yellow /directionmotorregisters_tb/dataIn
add wave -noupdate -color Yellow /directionmotorregisters_tb/regWr
add wave -noupdate -divider {Tx Manager}
add wave -noupdate -color Cyan -radix binary -childformat {{/directionmotorregisters_tb/dmotAddressToSend(7) -radix binary} {/directionmotorregisters_tb/dmotAddressToSend(6) -radix binary} {/directionmotorregisters_tb/dmotAddressToSend(5) -radix binary} {/directionmotorregisters_tb/dmotAddressToSend(4) -radix binary} {/directionmotorregisters_tb/dmotAddressToSend(3) -radix binary} {/directionmotorregisters_tb/dmotAddressToSend(2) -radix binary} {/directionmotorregisters_tb/dmotAddressToSend(1) -radix binary} {/directionmotorregisters_tb/dmotAddressToSend(0) -radix binary}} -subitemconfig {/directionmotorregisters_tb/dmotAddressToSend(7) {-color Cyan -height 15 -radix binary} /directionmotorregisters_tb/dmotAddressToSend(6) {-color Cyan -height 15 -radix binary} /directionmotorregisters_tb/dmotAddressToSend(5) {-color Cyan -height 15 -radix binary} /directionmotorregisters_tb/dmotAddressToSend(4) {-color Cyan -height 15 -radix binary} /directionmotorregisters_tb/dmotAddressToSend(3) {-color Cyan -height 15 -radix binary} /directionmotorregisters_tb/dmotAddressToSend(2) {-color Cyan -height 15 -radix binary} /directionmotorregisters_tb/dmotAddressToSend(1) {-color Cyan -height 15 -radix binary} /directionmotorregisters_tb/dmotAddressToSend(0) {-color Cyan -height 15 -radix binary}} /directionmotorregisters_tb/dmotAddressToSend
add wave -noupdate -color Cyan /directionmotorregisters_tb/dmotDataToSend
add wave -noupdate /directionmotorregisters_tb/dmotSendRequest
add wave -noupdate -color Yellow /directionmotorregisters_tb/dmotSendAuth
add wave -noupdate -divider {Register Bank}
add wave -noupdate /kart/REG_ADDR_MSB_NB_BITS
add wave -noupdate /kart/REG_ADDR_MAXNBREG_BITS
add wave -noupdate /kart/REG_ADDR_GET_BIT_POSITION
add wave -noupdate /kart/REG_ADDR_MSB_NB_BITS
add wave -noupdate -divider {Register Manager}
add wave -noupdate /directionmotorregisters_tb/I_DUT/U_manager/addressIn
add wave -noupdate /directionmotorregisters_tb/I_DUT/U_manager/dataIn
add wave -noupdate /directionmotorregisters_tb/I_DUT/U_manager/loadNew
add wave -noupdate /directionmotorregisters_tb/I_DUT/U_manager/p_int_reg_addr
add wave -noupdate /directionmotorregisters_tb/I_DUT/U_manager/p_registers
add wave -noupdate /directionmotorregisters_tb/I_DUT/U_manager/registersNb
add wave -noupdate -divider Target
add wave -noupdate -radix unsigned /directionmotorregisters_tb/I_DUT/targetCommand
add wave -noupdate -radix unsigned /directionmotorregisters_tb/I_DUT/target
add wave -noupdate -divider {Custom reg}
add wave -noupdate -radix binary /directionmotorregisters_tb/I_DUT/customReg1
add wave -noupdate -radix binary /directionmotorregisters_tb/I_DUT/customReg2
add wave -noupdate -radix binary /directionmotorregisters_tb/I_DUT/customReg3
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {49213194 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 338
configure wave -valuecolwidth 190
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ms
update
WaveRestoreZoom {42220406 ps} {57732943 ps}
run -all
