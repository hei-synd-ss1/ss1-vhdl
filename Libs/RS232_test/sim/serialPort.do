onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color Gray60 /serialport_tb/I_tester/c_BAUD_PERIOD
add wave -noupdate -color Gray60 /serialport_tb/I_tester/rst
add wave -noupdate -color Gray60 /serialport_tb/I_tester/clk
add wave -noupdate -color Gray60 /serialport_tb/I_tester/testInfo
add wave -noupdate -color Gray60 /serialport_tb/I_tester/subTestInfo
add wave -noupdate -divider Rx
add wave -noupdate -color Gold /serialport_tb/I_tester/rxd
add wave -noupdate /serialport_tb/U_rsRec/i_rxd_en
add wave -noupdate -radix unsigned /serialport_tb/U_rsRec/lvec_rx_counter
add wave -noupdate -radix unsigned /serialport_tb/U_rsRec/lvec_divider_counter
add wave -noupdate /serialport_tb/U_rsRec/lsig_divider_of
add wave -noupdate -radix unsigned /serialport_tb/U_rsRec/lvec_divider_sampling_counter
add wave -noupdate /serialport_tb/U_rsRec/lsig_divider_sampling_of
add wave -noupdate /serialport_tb/U_rsRec/lvec_state
add wave -noupdate /serialport_tb/U_rsRec/o_byte
add wave -noupdate -expand /serialport_tb/U_rsRec/lvec_sampling_values
add wave -noupdate /serialport_tb/U_rsRec/lsig_sampled_value
add wave -noupdate /serialport_tb/U_rsRec/lvec_rx_shift_reg
add wave -noupdate /serialport_tb/U_rsRec/o_byte_received
add wave -noupdate /serialport_tb/U_rsRec/o_frame_error
add wave -noupdate /serialport_tb/U_rsRec/o_illegalstate_error
add wave -noupdate /serialport_tb/U_rsRec/o_is_receiving
add wave -noupdate /serialport_tb/U_rsRec/o_parity_error
add wave -noupdate -divider Tx
add wave -noupdate /serialport_tb/U_rsTrans/g_BAUD_RATE_DIVIDER
add wave -noupdate /serialport_tb/U_rsTrans/g_DATA_BIT_NB
add wave -noupdate /serialport_tb/U_rsTrans/g_IDLE_STATE
add wave -noupdate /serialport_tb/U_rsTrans/g_LSB_FIRST
add wave -noupdate /serialport_tb/U_rsTrans/g_PARITY_IS_EVEN
add wave -noupdate /serialport_tb/U_rsTrans/g_STOP_BITS
add wave -noupdate /serialport_tb/U_rsTrans/g_USE_PARITY
add wave -noupdate /serialport_tb/U_rsTrans/i_data
add wave -noupdate /serialport_tb/U_rsTrans/i_rst
add wave -noupdate /serialport_tb/U_rsTrans/i_send
add wave -noupdate /serialport_tb/U_rsTrans/o_illegalstate_error
add wave -noupdate /serialport_tb/U_rsTrans/o_is_sending
add wave -noupdate -color {Dark Orchid} /serialport_tb/I_tester/txd
add wave -noupdate -color {Dark Orchid} /serialport_tb/I_tester/txd_en
add wave -noupdate -divider Reconstructed
add wave -noupdate -radix ascii /serialport_tb/U_rsRec1/o_byte
add wave -noupdate /serialport_tb/U_rsRec1/o_byte_received
add wave -noupdate /serialport_tb/U_rsRec1/o_frame_error
add wave -noupdate /serialport_tb/U_rsRec1/o_illegalstate_error
add wave -noupdate /serialport_tb/U_rsRec1/o_parity_error
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 4} {2579765591 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 384
configure wave -valuecolwidth 100
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
WaveRestoreZoom {2577219727 ps} {2603171955 ps}
