library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity write is
port ( 	clk : in std_logic;   ---system clock
       reset : in std_logic;  ---switching process
 	sda   : inout std_logic;  ----i2c data line
		scl   : out std_logic := '1'; ---i2c clock line
		seg   : in std_logic_vector(7 downto 0);
		min   : in std_logic_vector(7 downto 0);
		hor   : in std_logic_vector(7 downto 0);
		dia   : in std_logic_vector(7 downto 0);
		mes   : in std_logic_vector(7 downto 0);
		ani   : in std_logic_vector(7 downto 0);
	   dds   : in std_logic_vector(7 downto 0);
		l1    : out std_logic := '1');
end write;

architecture Behavioral of write is

type state is (start,state1,state2,state3,stop,finish); ---fsm
signal ps : state := start;

signal control : std_logic_vector(7 downto 0)     := x"0b"; --command data for write
signal add     : std_logic_vector(7 downto 0)     := x"00"; --address
signal datas    : std_logic_vector(7 downto 0)    := (seg(0) & seg(1) & seg(2) & seg(3) & seg(4) & seg(5) & seg(6) & seg(7)); -- := x"00"; --initial value for second	
signal datam    : std_logic_vector(7 downto 0)    := (min(0) & min(1) & min(2) & min(3) & min(4) & min(5) & min(6) & min(7)); -- := x"9A"; --x"9a";--initial value for minutes
signal datah    : std_logic_vector(7 downto 0)    := (hor(0) & hor(1) & hor(2) & hor(3) & hor(4) & hor(5) & hor(6) & hor(7)); -- := x"C4"; --x"c4";	--initial value for hours
signal datadate : std_logic_vector(7 downto 0)   := (dia(0) & dia(1) & dia(2) & dia(3) & dia(4) & dia(5) & dia(6) & dia(7)); -- := x"68"; --x"C0"; --x"80"; --initial value for day
signal datamon  : std_logic_vector(7 downto 0)  := (mes(0) & mes(1) & mes(2) & mes(3) & mes(4) & mes(5) & mes(6) & mes(7)); -- := x"00"; --x"88"; --x"48";	--initial value for month
signal dataye   : std_logic_vector(7 downto 0)   := (ani(0) & ani(1) & ani(2) & ani(3) & ani(4) & ani(5) & ani(6) & ani(7)); --:= x"00"; --x"02"; --x"10";	--initial value for year			 
signal datada   : std_logic_vector(7 downto 0) := (dds(0) & dds(1) & dds(2) & dds(3) & dds(4) & dds(5) & dds(6) & dds(7)); -- := x"00"; --x"40"; --x"8c";	--initial value for date
signal ack : std_logic := '1';								 
begin

--datas(7 downto 0)    <= seg(0) & seg(1) & seg(2) & seg(3) & seg(4) & seg(5) & seg(6) & seg(7);
--datam(7 downto 0)	   <= min(0) & min(1) & min(2) & min(3) & min(4) & min(5) & min(6) & min(7);
--datah(7 downto 0)    <= (hor(0) & hor(1) & hor(2) & hor(3) & hor(4) & hor(5) & hor(6) & hor(7));
--datada(7 downto 0)   <= (dia(0) & dia(1) & dia(2) & dia(3) & dia(4) & dia(5) & dia(6) & dia(7));
--datamon(7 downto 0)  <= (mes(0) & mes(1) & mes(2) & mes(3) & mes(4) & mes(5) & mes(6) & mes(7));
--dataye(7 downto 0)   <= (ani(0) & ani(1) & ani(2) & ani(3) & ani(4) & ani(5) & ani(6) & ani(7));
--datadate(7 downto 0) <= (dds(0) & dds(1) & dds(2) & dds(3) & dds(4) & dds(5) & dds(6) & dds(7));

process(reset,clk)------------------
variable i,j : integer := 0;
begin
if reset = '1' then
if clk'event and clk = '1' then
if ps = start then    ---i2c start condition
if i <= 250 then
i := i + 1;
sda <= '1';
scl <= '1';
elsif i > 250 and i <= 500 then
i := i + 1;
sda <= '0';
scl <= '1';
elsif i > 500 and i < 750 then
i := i + 1;
sda <= '0';
scl <= '0';
elsif i = 750 then
i := 0;
sda <= '0';
scl <= '0';
ps <= state1 ;
end if;
end if;
---------------------------------------------------------------------
if ps = state1 then   -----control word for write
if i <= 250 then
i := i + 1;
scl <= '0';
if j < 8 then
sda <= control(j);
elsif j = 8 then
sda <= 'Z';
ack <= sda;
end if;
elsif i > 250 and i <= 500 then
i := i + 1;
scl <= '1';
if j < 8 then
sda <= control(j);
elsif j = 8 then
sda <= 'Z';
ack <= sda;
end if;
elsif i > 500 and i < 750 then
i := i + 1;
scl <= '0';
if j < 8 then
sda <= control(j);
elsif j = 8 then
sda <= 'Z';
ack <= sda;
end if;
elsif i = 750 then
scl <= '0';
i := 0;
if j < 8 then
j := j + 1;
elsif j = 8 then
j := 0;
ps <= state2;
end if;
end if;
end if;
--------------------------------------------------------
if ps = state2 then   ----address send state
if i <= 250 then
i := i + 1;
scl <= '0';
if j < 8 then
sda <= add(j);  ---sending each bit of address
elsif j = 8 then
sda <= 'Z';
ack <= sda;
end if;
elsif i > 250 and i <= 500 then
i := i + 1;
scl <= '1';
if j < 8 then
sda <= add(j);
elsif j = 8 then
sda <= 'Z';
ack <= sda;
end if;
elsif i > 500 and i < 750 then
i := i + 1;
scl <= '0';
if j < 8 then
sda <= add(j);
elsif j = 8 then
sda <= 'Z';
ack <= sda;
end if;
elsif i = 750 then
scl <= '0';
i := 0;
if j < 8 then
j := j + 1;
elsif j = 8 then
j := 0;
case add  is    -----assigning address for each register
when x"00" =>
add <= x"80" ;
when x"80" =>
add <= x"40" ;
------------------------------------------------
when x"40" =>
add <= x"c0" ;
when x"c0" =>
add <= x"20" ;
when x"20" =>
add <= x"a0" ;
when x"a0" =>
add <= x"60" ;
when x"60" =>
add <= x"70" ;
when others =>
null;
------------------------------------------------
end case;
ps <= state3;
end if;
end if;
end if;
if ps = state3 then
if i <= 250 then
i := i + 1;
scl <= '0';
if j < 8 then
case add  is    ---assigning initial data for each register
when x"80"  =>
sda <= datas(j);
------------------------------------------------
when x"40" =>
sda <= datam(j);
when x"c0" =>
sda <= datah(j);
when x"20" =>
sda <= datada(j);
when x"a0" =>
sda <= datadate(j);
when x"60" =>
sda <= datamon(j);
when x"70" =>
sda <= dataye(j);
when others =>
null;
--------------------------------------------------
end case;
elsif j = 8 then
sda <= 'Z';
ack <= sda;
end if;
elsif i > 250 and i <= 500 then
i := i + 1;
scl <= '1';
if j < 8 then
case add is 
when x"80"  =>
sda <= datas(j);
------------------------------------------------
when x"40" =>
sda <= datam(j);
when x"c0" =>
sda <= datah(j);
when x"20" =>
sda <= datada(j);
when x"a0" =>
sda <= datadate(j);
when x"60" =>
sda <= datamon(j);
l1 <= '0';
when x"70" =>
sda <= dataye(j);
when others =>
null;
--------------------------------------------------
end case;
elsif j = 8 then
sda <= 'Z';
ack <= sda;
end if;
elsif i > 500 and i < 750 then
i := i + 1;
scl <= '0';
if j < 8 then
case add is
when x"80"  =>
sda <= datas(j);
------------------------------------------------
when x"40" =>
sda <= datam(j);
when x"c0" =>
sda <= datah(j);
when x"20" =>
sda <= datada(j);
when x"a0" =>
sda <= datadate(j);
when x"60" =>
sda <= datamon(j);
when x"70" =>
sda <= dataye(j);
when others =>
null;
--------------------------------------------------
end case;
elsif j = 8 then
sda <= 'Z';
ack <= sda;
end if;
elsif i = 750 then
scl <= '0';
i := 0;
if j < 8 then
j := j + 1;
elsif j = 8 then
j := 0;
ps <= stop;
end if;
end if;
end if;
--------------------------------------------------------
if ps = stop then    ----i2c stop condition 
if i <= 250 then
i := i + 1;
sda <= '0';
scl <= '1';
elsif i > 250 and i <= 500 then
i := i + 1;
sda <= '1';
scl <= '1';
elsif i > 500 and i < 750 then
i := i + 1;
sda <= '1';
scl <= '1';
elsif i = 750 then
i := 0;
sda <= '1';
scl <= '1';
case add  is
when x"70" =>
ps <= finish ;
when x"80" =>
ps <= start ;
------------------------------------------------
when x"40" =>
ps <= start ;
when x"c0" =>
ps <= start ;
when x"20" =>
ps <= start ;
when x"a0" =>
ps <= start ;
when x"60" =>
ps <= start ;
when others =>
null;
------------------------------------------------
end case; 
end if;
-----------------------------------------
end if;
end if;
end if;
end process;
end Behavioral;