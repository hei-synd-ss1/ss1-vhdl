onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock & Reset}
add wave -noupdate /i2cslave_tb/clock
add wave -noupdate /i2cslave_tb/reset
add wave -noupdate -divider I2C
add wave -noupdate /i2cslave_tb/sCl
add wave -noupdate /i2cslave_tb/sDa
add wave -noupdate -divider {i2c slave}
add wave -noupdate /i2cslave_tb/i_ack
add wave -noupdate /i2cslave_tb/i_data
add wave -noupdate /i2cslave_tb/i_done
add wave -noupdate /i2cslave_tb/i_write_mode
add wave -noupdate /i2cslave_tb/o_data
add wave -noupdate /i2cslave_tb/o_new_data
add wave -noupdate /i2cslave_tb/o_request_ack
add wave -noupdate -divider i2cTransmitter
add wave -noupdate /i2cslave_tb/send
add wave -noupdate /i2cslave_tb/dataIn
add wave -noupdate /i2cslave_tb/busy
add wave -noupdate -divider i2cReceiver
add wave -noupdate /i2cslave_tb/U_0/i_ack_bit
add wave -noupdate /i2cslave_tb/U_0/i_data_received
add wave -noupdate /i2cslave_tb/U_0/i_data_valid
add wave -noupdate /i2cslave_tb/U_0/o_is_transmitting
add wave -noupdate -divider i2cSlaveController
add wave -noupdate /i2cslave_tb/U_0/U_2/lsig_state
add wave -noupdate /i2cslave_tb/U_0/U_2/lvec_data_received
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {244841660 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 241
configure wave -valuecolwidth 80
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ms
update
WaveRestoreZoom {0 ps} {89648548 ps}
