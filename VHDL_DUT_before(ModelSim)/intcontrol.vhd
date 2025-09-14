LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

ENTITY INTcontrol IS
	generic ( MEMwitdh : integer :=12);
	PORT( 
			divclk,rst				: IN 	STD_LOGIC;
			MemRead 			: IN 	STD_LOGIC;
         		MemWrite 			: IN 	STD_LOGIC;	
			addressBUS		   	: IN 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
			DATA_bus 			: INOUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			SWch 					: IN STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			LEDR 					:OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			HEX0,HEX1 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX2,HEX3 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX4,HEX5 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			DivIFG				:OUT STD_LOGIC
			);
END INTcontrol;

ARCHITECTURE INTcontrol_arch OF INTcontrol IS

begin

end INTcontrol_arch;