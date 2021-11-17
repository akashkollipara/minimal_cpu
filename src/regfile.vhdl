entity reg32 is
	port(
		din	: in bit_vector (31 downto 0);
		clk, en	: in bit;
		dout	: out bit_vector (31 downto 0)
	    );
end entity;

architecture behavioral of reg32 is
	signal bitfields	: bit_vector (31 downto 0);
begin
	process(clk)
	begin
		if(clk'event and clk = '1') then
			if(en = '1') then
				bitfields <= din;
			end if;
		end if;
	end process;
	dout <= bitfields;
end behavioral;



library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile is
	port(
		rs_addr, rt_addr, rd_addr	: in bit_vector (4 downto 0);
		din				: in bit_vector (31 downto 0);
		clk, en				: in bit;
		rs_out, rt_out			: out bit_vector (31 downto 0)
	    );
end entity;

architecture behavioral of regfile is
	type reg_bank		is array (natural range <>) of bit_vector (31 downto 0);
	signal reg_file		: reg_bank(0 to 31);
begin
	process(clk)
	begin
		if(clk'event and clk = '1') then
			if(en = '1') then
				reg_file(to_integer(unsigned(to_stdlogicvector(rd_addr)))) <= din;
			end if;
			rs_out <= reg_file(to_integer(unsigned(to_stdlogicvector(rs_addr))));
			rt_out <= reg_file(to_integer(unsigned(to_stdlogicvector(rt_addr))));
		end if;
	end process;
end behavioral;




entity reg32_tb is
end entity;

architecture tb of reg32_tb is
	signal din, dout: bit_vector (31 downto 0);
	signal en, clk	: bit;

	component reg32 is
		port(
			din	: in bit_vector (31 downto 0);
			clk, en	: in bit;
			dout	: out bit_vector (31 downto 0)
		    );
	end component;

	constant delay	: time := 350 ps;

begin

	reg_uut: reg32 port map(
					din => din,
					clk => clk,
					en => en,
					dout => dout
			       );
	test_process: process
	begin
		din <= "00000000000000000000000000001111";
		en <= '0';
		clk <= '0';
		wait for delay;
		en <= '1';
		clk <= '1';
		wait for delay;
		clk <= '0';
		en <= '0';
		wait;
	end process;
end tb;


entity regfile_tb is
end entity;

architecture tb of regfile_tb is
	signal rs_addr, rt_addr, rd_addr	: bit_vector (4 downto 0);
	signal din, rs_out, rt_out		: bit_vector (31 downto 0);
	signal en, clk				: bit;

	component regfile is
		port(
			rs_addr, rt_addr, rd_addr	: in bit_vector (4 downto 0);
			din				: in bit_vector (31 downto 0);
			clk, en				: in bit;
			rs_out, rt_out			: out bit_vector (31 downto 0)
		    );
	end component;

	constant delay	: time := 350 ps;

begin

	reg_uut: regfile port map(
					rs_addr => rs_addr,
					rt_addr => rt_addr,
					rd_addr => rd_addr,
					din => din,
					rs_out => rs_out,
					rt_out => rt_out,
					clk => clk,
					en => en
			       );
	test_process: process
		begin
			rs_addr <= "00000";
			rt_addr <= "00000";
			rd_addr <= "00000";
			din <= "00000000000000000000000000000001";
			clk <= '0';
			en <= '0';
			wait for delay;
			clk <= '1';
			en <= '1';
			wait for delay;
			clk <= '0';
			en <= '0';
			rd_addr <= "00001";
			din <= "00000000000000000000000000000011";
			wait for delay;
			clk <= '1';
			en <= '1';
			wait for delay;
			clk <= '0';
			en <= '0';
			rt_addr <= "00001";
			wait for delay;
			wait;
		end process;
end tb;
