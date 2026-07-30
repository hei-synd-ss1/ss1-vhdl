onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clock & Reset}
add wave -noupdate -color Gray60 /i2cmasterslave_tb/reset
add wave -noupdate -color Gray60 /i2cmasterslave_tb/clock
add wave -noupdate -color Gray60 /i2cmasterslave_tb/I_tester/lvec_test_info
add wave -noupdate -color Gray60 /i2cmasterslave_tb/I_tester/lvec_test_subinfo
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/lvec_data_cnt
add wave -noupdate -color {Medium Blue} -label SCL /i2cmasterslave_tb/lsig_i_scl_master
add wave -noupdate -color {Medium Blue} -label SDA /i2cmasterslave_tb/lsig_i_sda_master
add wave -noupdate -label {Master DO} /i2cmasterslave_tb/I_i2cMaster_DUT/i_data
add wave -noupdate -label {Slave DI} /i2cmasterslave_tb/I_i2cSlave_DUT/lvec_data_received
add wave -noupdate -label {Slave DO} /i2cmasterslave_tb/I_i2cSlave_DUT/i_data
add wave -noupdate -label {Master DI} /i2cmasterslave_tb/I_i2cMaster_DUT/lsig_data_received
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {Master Control}
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/lvec_state
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/lvec_transaction_state
add wave -noupdate -expand -group Receiver /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/i_rec_data_received
add wave -noupdate -expand -group Receiver /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/i_rec_data_valid
add wave -noupdate -expand -group Receiver /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/i_rec_ack_bit
add wave -noupdate -expand -group Receiver /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/o_rec_slave_write
add wave -noupdate -expand -group Transmitter /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/i_tr_busy
add wave -noupdate -expand -group Transmitter /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/o_tr_ack
add wave -noupdate -expand -group Transmitter /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/o_tr_data_to_send
add wave -noupdate -expand -group Transmitter /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/o_tr_send_data
add wave -noupdate -expand -group Transmitter /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/o_tr_send_start
add wave -noupdate -expand -group Transmitter /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/o_tr_send_stop
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/i_ack
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/i_data
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/i_ncs
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/i_repeat_start
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/i_send_data
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/o_data
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/o_data_rec_ack_request
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/o_data_received
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/o_error
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/o_frame_ack
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/o_request_transaction
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/lsig_rw_mode
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cMasterController/lsig_start_restart
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {Master transmitter}
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/lvec_state
add wave -noupdate -color {Cornflower Blue} /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/i_scl
add wave -noupdate -color {Cornflower Blue} /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/o_scl
add wave -noupdate -color {Cornflower Blue} /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/o_sda
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/o_bus_owned
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/lsig_scl_en
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/lsig_scl_toggle
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/lvec_scl_cnt
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/lvec_scl_phase
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/lsig_stretching_detected
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/lvec_data_cnt
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cTransmitter/lvec_data
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {Master receiver}
add wave -noupdate -color {Cornflower Blue} /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cReceiver/i_scl
add wave -noupdate -color {Cornflower Blue} /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cReceiver/i_sda
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cReceiver/o_bus_asserted
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cReceiver/lsig_data_indicated
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cReceiver/lsig_startCondition
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cReceiver/lsig_stopCondition
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cReceiver/lvec_dataShiftReg
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cReceiver/lvec_bitCounter
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cReceiver/lsig_endOfWordNoAck
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cReceiver/lsig_endOfWord
add wave -noupdate /i2cmasterslave_tb/I_i2cMaster_DUT/I_i2cReceiver/lsig_bus_asserted
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {Slave ctrl}
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/lvec_state
add wave -noupdate -expand -group Receiver /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/i_rec_busy_receiving
add wave -noupdate -expand -group Receiver /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/i_rec_ack
add wave -noupdate -expand -group Receiver /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/i_rec_data
add wave -noupdate -expand -group Receiver /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/i_rec_data_received
add wave -noupdate -expand -group Receiver /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/i_rec_start_restart
add wave -noupdate -expand -group Receiver /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/i_rec_stop
add wave -noupdate -expand -group Receiver /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_rec_slave_write
add wave -noupdate -expand -group Transmitter /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/i_tr_busy
add wave -noupdate -expand -group Transmitter /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_tr_ack
add wave -noupdate -expand -group Transmitter /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_tr_data_to_send
add wave -noupdate -expand -group Transmitter /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_tr_send
add wave -noupdate -expand -group Transmitter /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_tr_send_ack
add wave -noupdate -expand -group Transmitter /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_tr_wait
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_data_request
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_data
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_ack_request
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/i_ack
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_frame_ack
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_data_received
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/i_data
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/i_wait
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_err_sent_corrupted
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_transfer_done
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/o_repeated_start
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/i_address
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/i_address_is10b
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/lsig_send_data
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/lsig_data_received_old
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/lvec_sent_data
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/lsig_request_ack_old
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/lvec_addr
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cSlaveController/lsig_addr_10b_ok
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {Slave receiver}
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cReceiver/i_scl
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cReceiver/i_sda
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cReceiver/o_bus_asserted
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cReceiver/lsig_data_indicated
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cReceiver/lsig_startCondition
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cReceiver/lsig_stopCondition
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cReceiver/lvec_dataShiftReg
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cReceiver/lvec_bitCounter
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cReceiver/lsig_endOfWordNoAck
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cReceiver/lsig_endOfWord
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cReceiver/lsig_bus_asserted
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {Slave transmitter}
add wave -noupdate -color {Cornflower Blue} /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cTransmitter/o_scl
add wave -noupdate -color {Cornflower Blue} /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cTransmitter/o_sda
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cTransmitter/lvec_state
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cTransmitter/lvec_data
add wave -noupdate /i2cmasterslave_tb/I_i2cSlave_DUT/I_i2cTransmitter/lvec_data_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {451679254 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 406
configure wave -valuecolwidth 140
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
WaveRestoreZoom {333496926 ps} {684078060 ps}
