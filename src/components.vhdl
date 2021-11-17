
--==================== 
-- Mux 2x1
--==================== 
entity mux_32b_2x1 is
	-- Defining port for Mux 2x1
	port(
		a, b	: in bit_vector (31 downto 0);
		sel	: in bit;
		y	: out bit_vector (31 downto 0));
end entity;

architecture behavioral of mux_32b_2x1 is
begin
	-- Case logic to select input
	process(a, b, sel) is
	begin
		case sel is
			when '0' =>
				y <= a;
			when '1' =>
				y <= b;
		end case;
	end process;
end behavioral;


--==================== 
-- Mux 4x1
--==================== 
entity mux_32b_4x1 is
	-- Defining port for Mux 4x1
	port(
		a, b, c, d	: in bit_vector (31 downto 0);
		sel		: in bit_vector (1 downto 0);
		y		: out bit_vector (31 downto 0));
end entity;

architecture behavioral of mux_32b_4x1 is
begin
	-- Case logic to select input
	process(a, b, c, d, sel) is
	begin
		case sel is
			when "00" =>
				y <= a;
			when "01" =>
				y <= b;
			when "10" =>
				y <= c;
			when "11" =>
				y <= d;
		end case;
	end process;
end behavioral;


--==================== 
-- Logic Mix
--==================== 
entity logic_mix is
	port(
		a, b		: in bit_vector (31 downto 0);
		o_and, o_or	: out bit_vector (31 downto 0);
		o_xor, o_lui	: out bit_vector (31 downto 0);
		o_nor, o_nand	: out bit_vector (31 downto 0));
end entity;

architecture behavioral of logic_mix is
begin
	o_and <= a and b;
	o_or <= a or b;
	o_xor <= a xor b;
	o_nor <= a nor b;
	o_nand <= a nand b;
	o_lui(31 downto 16) <= b(15 downto 0);
end behavioral;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--==================== 
-- Barrel Shifter
--==================== 
entity barrel_shifter is
	-- Defining ports for barrel shifter
	port(
		a, b	: in bit_vector (31 downto 0);
		cntr	: in bit;
		opr	: in bit;
		y	: out bit_vector (31 downto 0));
end entity;

architecture behavioral of barrel_shifter is
	-- Create signal for shift_size
	signal shift_size	: std_logic_vector (4 downto 0);
begin
	-- Convert bit_vector to std_logic_vector
	shift_size <= to_stdlogicvector(a (4 downto 0));
	-- Process to define shift logic
	process(shift_size, b, cntr, opr)
	begin
		case cntr is
			when '0' =>
				-- Logical left shifter
				y <= b sll to_integer(unsigned(shift_size));
			when '1' =>
				case opr is
					when '0' =>
						-- Logical right shifter
						y <= b srl to_integer(unsigned(shift_size));
					when '1' =>
						-- Arithmatic right shifter
						y <= b sra to_integer(unsigned(shift_size));
				end case;
		end case;
	end process;
end behavioral;


--==================== 
-- Adder
--==================== 
entity partial_full_adder is
	-- Defining port for partial full adder
	port(
		a, b, c	: in bit;
		s, p, g	: out bit
	);
end partial_full_adder;

architecture behavioral of partial_full_adder is
begin
	-- Building logic for 1bit partial full adder
	-- This unit computes, sum, p and g
	s <= a xor b xor c;
	p <= a xor b;
	g <= a and b;
end behavioral;

entity cl_adder_32b is
	-- Defining port for carry look-ahead adder
	port(
		a, b	: in bit_vector (31 downto 0);
		s	: out bit_vector (31 downto 0);
		z, c, ov: out bit;
		sub	: in bit
	);
end cl_adder_32b;

architecture behavioral of cl_adder_32b is
	-- Instantiate partial full adder core
	component partial_full_adder is
		port(
			a, b, c	: in bit;
			s, p, g : out bit
		    );
	end component;

	-- Signals for connecting the PFA cores
	signal g, p, bp	: bit_vector (31 downto 0);
	signal sum	: bit_vector (31 downto 0);
	signal cin, zs	: bit_vector (32 downto 0);
begin
	-- If sub is enabled then carry needs to be set for generating
	-- complement of the number
	cin(0) <= sub;
	zs(0) <= '0';
	-- Finding 2's complement
	complement_b: for i in 0 to 31 generate
		bp(i) <= b(i) xor sub;
	end generate complement_b;

	-- Generate the connections for 32 PFA core to build 32b CLA adder
	connect_pfas: for i in 0 to 31 generate
		pfa: partial_full_adder
		port map(
				a => a(i),
				b => bp(i),
				c => cin(i),
				s => sum(i),
				p => p(i),
				g => g(i)
			);
		cin(i+1) <= g(i) or (p(i) and cin(i));
		zs(i+1) <= zs(i) or sum(i);
	end generate connect_pfas;
	c <= cin(32);
	ov <= cin(32) xor cin(31);
	z <= not zs(32);
	s <= sum;
end behavioral;
