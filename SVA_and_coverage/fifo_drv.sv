`define DRV_IF fifo_intf.fifo_drv_mp.fifo_drv_cb
class fifo_drv;
	virtual interface fifo_intf fifo_vif;

	// create a mailbox to receive pkt from gen
	mailbox gen2drv;		// Incoming pkt (GEN-->DRV)

	function new (virtual interface fifo_intf intf, mailbox mbx);	// Class constructor
		this.fifo_vif = intf;
		this.gen2drv = mbx;
	endfunction

	task reset;		// On Reset, reset interface signals to default values
		wait(!f_intf.rstN);
		$display("\tDRIVER :: %0t ns \t reset task starting...\n ",$time);
		`DRV_IF.wr_en <= 0;
		`DRV_IF.rd_en <= 0;
		`DRV_IF.data_in <= 'h0;
		wait(fifo_vif.rstN);
		$display("\tDRIVER :: %0t ns \t reset task finishing...\n ",$time);
	endtask

	task run;		// This task puts generated pkts from gen to drv
		forever begin
			fifo_trans trans;

			`DRV_IF.wr_en<=0;
			`DRV_IF.rd_en<=0;

			gen2drv.get(trans);

			$display("\tDRIVER::%0t Getting data packets from Generator",$time);

			@(posedge fifo_vif.fifo_drv_mp.clk);
			if(trans.wr_en)
			begin
				`DRV_IF.wr_en <= trans.wr_en;
				`DRV_IF.data_in <= trans.data_in;

				@(posedge fifo_vif.fifo_drv_mp.clk);
			end

			if(trans.rd_en) begin
				`PROBE_IF.rd_en <= trans.rd_en;
				@(posedge fifo_vif.fifo_probe_mp.clk);
				`PROBE_IF.rd_en <= 0;
				@(posedge fifo_vif.fifo_probe_mp.clk);
				trans.data_out <= `PROBE_IF.data_out;
				$display("\tPROBE::%0t Reading data from fifo %0h",$time,trans.data_out);
			end

		end
	endtask

endclass	