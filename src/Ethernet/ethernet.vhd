library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ethernet_pkg.all;


entity ethernet is
	generic (
		PACKET_DATA_SIZE: 		integer := 100;
		MAC_SOURCE: 			std_logic_vector(47 downto 0) := x"001122334455";
		MAC_DESTINATION: 		std_logic_vector(47 downto 0) := x"00D86119493B"
	);
	port (
		eth_rst_n:		in 		std_logic := '0';
		
		rx_clk:			in 		std_logic := '0';
		rx_dv:			in 		std_logic := '0';
		rxd:			in 		std_logic_vector(3 downto 0);
		rx_fifo_en:		in	 	std_logic;
		rx_fifo_dout: 	out		std_logic_vector(3 downto 0);
		rx_pkt_rdy:		out 	std_logic;
		fifo_pout:		out		std_logic_vector(8*PACKET_DATA_SIZE-1 downto 0);
		fifo_clr:		in		std_logic := '0'
	);
end ethernet;

architecture behavioral of ethernet is
	component ethernet_rx
		generic (
			DATA_BYTES: 		integer := 46;
			MAC_SOURCE:			std_logic_vector(48-1 downto 0) := x"001122334455"
		);
		port (
			rx_clk: 	in		std_logic;
			rst_n:		in		std_logic;
			rx_d:		in		std_logic_vector(3 downto 0);
			rx_dv:		in		std_logic;
			fifo_en:	in		std_logic := '0';

			fifo_out:	out		std_logic_vector(3 downto 0);
			pkt_ready:	out		std_logic;
			
			fifo_pout:	out		std_logic_vector(8*DATA_BYTES-1 downto 0);
			fifo_clr:	in		std_logic := '0'
		);
	end component;


	signal header: t_ethernet_header := (
		mac_dst => MAC_DESTINATION,
		mac_src => MAC_SOURCE,
		ip_type => x"0000"
	);

begin


	eth_rx: ethernet_rx 
		generic map(
			DATA_BYTES => PACKET_DATA_SIZE
		)
		port map(
			rx_clk => rx_clk,
			rst_n => eth_rst_n,
			rx_d => rxd,
			rx_dv => rx_dv,
			fifo_en => rx_fifo_en,
			fifo_out => rx_fifo_dout,
			pkt_ready => rx_pkt_rdy,
			fifo_pout => fifo_pout,
			fifo_clr => fifo_clr
		);

end behavioral ;

