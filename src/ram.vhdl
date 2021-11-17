library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
	port(
		addr	: in bit_vector (31 downto 0);
		din	: in bit_vector (31 downto 0);
		clk, en	: in bit;
		dout	: out bit_vector(31 downto 0)
	    );
end entity;

architecture behavioral of ram is
	type cell	is array (natural range <>) of bit_vector (7 downto 0);
	signal memory	: cell(0 to 63);
	signal l_addr	: bit_vector (6 downto 0);
begin
	process(clk)
	begin
		l_addr <= addr(6 downto 0);
		if(clk'event and clk = '1') then
			if(en = '1') then
				memory(to_integer(unsigned(to_stdlogicvector(l_addr)))) <= din(7 downto 0);
				memory(to_integer(unsigned(to_stdlogicvector(l_addr))) + 8) <= din(15 downto 8);
				memory(to_integer(unsigned(to_stdlogicvector(l_addr))) + 16) <= din(23 downto 16);
				memory(to_integer(unsigned(to_stdlogicvector(l_addr))) + 24) <= din(31 downto 24);
			end if;
			dout(7 downto 0) <= memory(to_integer(unsigned(to_stdlogicvector(l_addr))));
			dout(15 downto 8) <= memory(to_integer(unsigned(to_stdlogicvector(l_addr))) + 8);
			dout(23 downto 16) <= memory(to_integer(unsigned(to_stdlogicvector(l_addr))) + 16);
			dout(31 downto 24) <= memory(to_integer(unsigned(to_stdlogicvector(l_addr))) + 24);
		end if;
	end process;
end behavioral;
