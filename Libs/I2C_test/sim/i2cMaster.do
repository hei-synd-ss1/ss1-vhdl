onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock & Reset}
add wave -noupdate -color Gray60 /i2cmaster_tb/clock
add wave -noupdate -color Gray60 /i2cmaster_tb/reset
add wave -noupdate -color Gray60 /i2cmaster_tb/I_tester/lsig_test_info
add wave -noupdate -divider {Master Control}
add wave -noupdate /i2cmaster_tb/I_i2cMaster_DUT/I_i2cMasterController/lvec_state
add wave -noupdate -color Gold /i2cmaster_tb/lsig_master_ncs
add wave -noupdate -color Gold /i2cmaster_tb/lsig_master_we
add wave -noupdate -color {Dark Orchid} /i2cmaster_tb/lsig_master_request_new_data
add wave -noupdate -color Gold /i2cmaster_tb/lvec_master_data_to_send
add wave -noupdate -color {Dark Orchid} /i2cmaster_tb/lvec_master_data_received
add wave -noupdate -color {Dark Orchid} /i2cmaster_tb/lsig_master_request_ack
add wave -noupdate -color Gold /i2cmaster_tb/lsig_master_ack
add wave -noupdate -color Gold /i2cmaster_tb/I_i2cMaster_DUT/i_repeated_start
add wave -noupdate -divider {Slave Control}
add wave -noupdate /i2cmaster_tb/I_i2cSlave_DUT/I_i2cSlaveController/lvec_state
add wave -noupdate -color Gold /i2cmaster_tb/lsig_slave_we
add wave -noupdate -color {Dark Orchid} /i2cmaster_tb/lsig_slave_new_data
add wave -noupdate -color Gold /i2cmaster_tb/lvec_slave_data_to_send
add wave -noupdate -color {Dark Orchid} /i2cmaster_tb/lvec_slave_data_received
add wave -noupdate -color {Dark Orchid} /i2cmaster_tb/lsig_slave_request_ack
add wave -noupdate -color Gold /i2cmaster_tb/lsig_slave_ack
add wave -noupdate -color {Dark Orchid} /i2cmaster_tb/lsig_slave_transfer_done
add wave -noupdate -color Gold /i2cmaster_tb/lsig_slave_wait
add wave -noupdate -color {Dark Orchid} /i2cmaster_tb/lsig_slave_error
add wave -noupdate -color {Dark Orchid} /i2cmaster_tb/lsig_slave_repeated_start
add wave -noupdate -divider I2C
add wave -noupdate -color {Cornflower Blue} /i2cmaster_tb/lsig_i_sda_master
add wave -noupdate -color {Cornflower Blue} /i2cmaster_tb/lsig_i_scl_master
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {1241992773 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 350
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
WaveRestoreZoom {1097450295 ps} {1395061889 ps}
