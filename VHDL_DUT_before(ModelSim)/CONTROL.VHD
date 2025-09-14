		-- control module (implements MIPS control unit)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY control IS
   PORT( 	
	Opcode 		: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
	RegDst 		: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	ALUSrc 		: OUT 	STD_LOGIC;
	MemtoReg 	: OUT 	STD_LOGIC;
	RegWrite 	: OUT 	STD_LOGIC;
	MemRead 	: OUT 	STD_LOGIC;
	MemWrite 	: OUT 	STD_LOGIC;
	Branch 		: OUT 	STD_LOGIC;
	Jump		: OUT	STD_LOGIC;
	ALUop 		: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	clock, reset	: IN 	STD_LOGIC );

END control;

ARCHITECTURE behavior OF control IS

	SIGNAL  R_type,I_type, slti, Lui, Lw, Sw, Beq,Bne,jmp,jal 	: STD_LOGIC;

BEGIN           
				-- Code to generate control signals using opcode bits
	R_type 	<=  '1'  WHEN ( Opcode = "000000" or Opcode = "011100")  ELSE '0';

	I_type 	<=  '1'  WHEN  (Opcode = "001000" or Opcode = "001100" or Opcode = "001101" or Opcode =  "001110" ) else '0'; --addi,andi,ori,xori

	slti 		<=  '1'  WHEN  Opcode = "001010"  ELSE '0' ;
	Lui		<=  '1'  WHEN  Opcode = "001111"  ELSE '0';
	Lw          	<=  '1'  WHEN  Opcode = "100011"  ELSE '0';
 	Sw          	<=  '1'  WHEN  Opcode = "101011"  ELSE '0';
	
   	Beq         	<=  '1'  WHEN  Opcode = "000100"  ELSE '0';
	Bne		<=  '1'  WHEN  Opcode = "000101"  ELSE '0';

	jmp		<=  '1'  WHEN  Opcode = "000010"  ELSE '0';
	jal		<=  '1'  WHEN  Opcode = "000011"  ELSE '0';


  	RegDst(1)    	<=  jal;
	RegDst(0)    	<=  R_type;
 	ALUSrc  	<=  Lw OR Sw OR I_type or Lui or slti;
	MemtoReg 	<=  Lw;
  	RegWrite 	<=  R_type OR Lw OR I_type OR jal or Lui or slti;
  	MemRead 	<=  Lw;
   	MemWrite 	<=  Sw; 
 	Branch      	<=  Beq or Bne; 
	Jump 		<=  jmp or jal ;
	ALUOp( 1 ) 	<=  R_type;
	ALUOp( 0 ) 	<=  Beq or Bne; 

   END behavior;


