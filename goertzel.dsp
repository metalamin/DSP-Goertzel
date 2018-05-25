{*************************************************************************
 *
 *  This sample program is organized into the following sections:
 *
 *  Assemble time constants
 *  Interrupt vector table
 *  ADSP 2181 intialization
 *  ADSP 1847 Codec intialization
 *  Interrupt service routines
 *
 *         Busque la cadena: * LAB_TDS * para saber donde debe cambiar cosas
 ***************************************************************************}



.module/RAM/ABS=0 loopback;



{******************************************************************************
 *
 *  Assemble time constants
 *
 ******************************************************************************}

.const  IDMA=                   0x3fe0;
.const  BDMA_BIAD=              0x3fe1;
.const  BDMA_BEAD=              0x3fe2;
.const  BDMA_BDMA_Ctrl=         0x3fe3;
.const  BDMA_BWCOUNT=           0x3fe4;
.const  PFDATA=                 0x3fe5;
.const  PFTYPE=                 0x3fe6;

.const  SPORT1_Autobuf=         0x3fef;
.const  SPORT1_RFSDIV=          0x3ff0;
.const  SPORT1_SCLKDIV=         0x3ff1;
.const  SPORT1_Control_Reg=     0x3ff2;
.const  SPORT0_Autobuf=         0x3ff3;
.const  SPORT0_RFSDIV=          0x3ff4;
.const  SPORT0_SCLKDIV=         0x3ff5;
.const  SPORT0_Control_Reg=     0x3ff6;
.const  SPORT0_TX_Channels0=    0x3ff7;
.const  SPORT0_TX_Channels1=    0x3ff8;
.const  SPORT0_RX_Channels0=    0x3ff9;
.const  SPORT0_RX_Channels1=    0x3ffa;
.const  TSCALE=                 0x3ffb;
.const  TCOUNT=                 0x3ffc;
.const  TPERIOD=                0x3ffd;
.const  DM_Wait_Reg=            0x3ffe;
.const  System_Control_Reg=     0x3fff;


.var/dm/ram/circ                rx_buf[3];      /* Status + L data + R data */
.var/dm/ram/circ                tx_buf[3];      /* Cmd + L data + R data    */
.var/dm/ram/circ                init_cmds[13];
.var/dm                         stat_flag;

.const N=			800;
.const tonos=		8;
.const tonos_2=		16;
	
.var/dm/ram/circ			q1q2[tonos_2];
.var/dm						contaN;
.var/dm						sqr[tonos];
.var/dm/ram/circ			coefs[tonos];
.var/dm						ganancia;
.var/dm						cambia;
.var/dm						umbral;

.init coefs[00]: 27980,26956,25701,24219;
.init coefs[04]: 19073,16325,13085,9315;
.init ganancia: 40;
.init umbral: 8;

{***************************************************************************}



.init tx_buf:   0xc000, 0x0000, 0x0000; /* Initially set MCE        */

.init init_cmds:
        0xc000,     {
                        Left input control reg
                        b7-6: 0=left line 1
                              1=left aux 1
                              2=left line 2
                              3=left line 1 post-mixed loopback
                        b5-4: res
                        b3-0: left input gain x 1.5 dB
                    }
        0xc100,     {
                        Right input control reg
                        b7-6: 0=right line 1
                              1=right aux 1
                              2=right line 2
                              3=right line 1 post-mixed loopback
                        b5-4: res
                        b3-0: right input gain x 1.5 dB
                    }
        0xc288,     {
                        left aux 1 control reg
                        b7  : 1=left aux 1 mute
                        b6-5: res
                        b4-0: gain/atten x 1.5, 08= 0dB, 00= 12dB
                    }
        0xc388,     {
                        right aux 1 control reg
                        b7  : 1=right aux 1 mute
                        b6-5: res
                        b4-0: gain/atten x 1.5, 08= 0dB, 00= 12dB
                    }
        0xc488,     {
                        left aux 2 control reg
                        b7  : 1=left aux 2 mute
                        b6-5: res
                        b4-0: gain/atten x 1.5, 08= 0dB, 00= 12dB
                    }
        0xc588,     {
                        right aux 2 control reg
                        b7  : 1=right aux 2 mute
                        b6-5: res
                        b4-0: gain/atten x 1.5, 08= 0dB, 00= 12dB
                    }
        0xc680,     {
                        left DAC control reg
                        b7  : 1=left DAC mute
                        b6  : res
                        b5-0: attenuation x 1.5 dB
                    }
        0xc780,     {
                        right DAC control reg
                        b7  : 1=right DAC mute
                        b6  : res
                        b5-0: attenuation x 1.5 dB
                    }



{---------------------------------------------------------------}
        0xc850,   {  * LAB_TDS * Usamos una fs de 8000Hz
                              0=  8.
                              1=  5.5125
                              2= 16.
                              3= 11.025
                              4= 27.42857
                              5= 18.9
                              6= 32.
                              7= 22.05
                              8=   .
                              9= 37.8
                              a=   .
                              b= 44.1
                              c= 48.
                              d= 33.075
                              e=  9.6
                              f=  6.615
----------------------------------------------------------------
                              }




        0xc909,     {
                        interface configuration reg
                        b7-4: res
                        b3  : 1=autocalibrate
                        b2-1: res
                        b0  : 1=playback enabled
                    }
        0xca00,     {
                        pin control reg
                        b7  : logic state of pin XCTL1
                        b6  : logic state of pin XCTL0
                        b5  : master - 1=tri-state CLKOUT
                              slave  - x=tri-state CLKOUT
                        b4-0: res
                    }
        0xcc40,     {
                        miscellaneous information reg
                        b7  : 1=16 slots per frame, 0=32 slots per frame
                        b6  : 1=2-wire system, 0=1-wire system
                        b5-0: res
                    }
        0xcd00;     {
                        digital mix control reg
                        b7-2: attenuation x 1.5 dB
                        b1  : res
                        b0  : 1=digital mix enabled
                    }



{******************************************************************************
 *
 *  Interrupt vector table
 *
 ******************************************************************************}
        jump start;  rti; rti; rti;     {00: reset }
        rti;         rti; rti; rti;     {04: IRQ2 }
        rti;         rti; rti; rti;     {08: IRQL1 }
        rti;         rti; rti; rti;     {0c: IRQL0 }
        ar = dm(stat_flag);             {10: SPORT0 tx }
        ar = pass ar;
        if eq rti;
        jump next_cmd;
        jump input_samples;             {14: SPORT1 rx }
                     rti; rti; rti;
        ax0=1;
        dm(stat_flag)=ax0;
        jump irqe;     {18: IRQE }
        rti;
        rti;         rti; rti; rti;     {1c: BDMA }
        rti;         rti; rti; rti;     {20: SPORT1 tx or IRQ1 }
        rti;         rti; rti; rti;     {24: SPORT1 rx or IRQ0 }
        rti;         rti; rti; rti;     {28: timer }
        rti;         rti; rti; rti;     {2c: power down }


{******************************************************************************
 *
 *  ADSP 2181 intialization
 *
 ******************************************************************************}
start:

        i0 = ^rx_buf;
        l0 = %rx_buf;
        i1 = ^tx_buf;
        l1 = %tx_buf;
        i3 = ^init_cmds;
        l3 = %init_cmds;
		
		

        m1 = 1;
		m2= 0;
		m3= -1;
		m4=1;

		l2=%q1q2;
		l5=%sqr;
		l4=%coefs;

{================== S E R I A L   P O R T   #0   S T U F F ==================}
        ax0 = b#0000001010000111;   dm (SPORT0_Autobuf) = ax0;
            {   |||!|-/!/|-/|/|+- receive autobuffering 0=off, 1=on
                |||!|  ! |  | +-- transmit autobuffering 0=off, 1=on
                |||!|  ! |  +---- | receive m?
                |||!|  ! |        | m1
                |||!|  ! +------- ! receive i?
                |||!|  !          ! i0
                |||!|  !          !
                |||!|  +========= | transmit m?
                |||!|             | m1
                |||!+------------ ! transmit i?
                |||!              ! i1
                |||!              !
                |||+============= | BIASRND MAC biased rounding control bit
                ||+-------------- 0
                |+--------------- | CLKODIS CLKOUT disable control bit
                +---------------- 0
            }

        ax0 = 0;    dm (SPORT0_RFSDIV) = ax0;
            {   RFSDIV = SCLK Hz/RFS Hz - 1 }
        ax0 = 0;    dm (SPORT0_SCLKDIV) = ax0;
            {   SCLK = CLKOUT / (2  (SCLKDIV + 1) }
        ax0 = b#1000011000001111;   dm (SPORT0_Control_Reg) = ax0;
            {   multichannel
                ||+--/|!||+/+---/ | number of bit per word - 1
                |||   |!|||       | = 15
                |||   |!|||       |
                |||   |!|||       |
                |||   |!||+====== ! 0=right just, 0-fill; 1=right just, signed
                |||   |!||        ! 2=compand u-law; 3=compand A-law
                |||   |!|+------- receive framing logic 0=pos, 1=neg
                |||   |!+-------- transmit data valid logic 0=pos, 1=neg
                |||   |+========= RFS 0=ext, 1=int
                |||   +---------- multichannel length 0=24, 1=32 words
                ||+-------------- | frame sync to occur this number of clock
                ||                | cycle before first bit
                ||                |
                ||                |
                |+--------------- ISCLK 0=ext, 1=int
                +---------------- multichannel 0=disable, 1=enable
            }
            {   non-multichannel
                |||!|||!|||!+---/ | number of bit per word - 1
                |||!|||!|||!      | = 15
                |||!|||!|||!      |
                |||!|||!|||!      |
                |||!|||!|||+===== ! 0=right just, 0-fill; 1=right just, signed
                |||!|||!||+------ ! 2=compand u-law; 3=compand A-law
                |||!|||!|+------- receive framing logic 0=pos, 1=neg
                |||!|||!+-------- transmit framing logic 0=pos, 1=neg
                |||!|||+========= RFS 0=ext, 1=int
                |||!||+---------- TFS 0=ext, 1=int
                |||!|+----------- TFS width 0=FS before data, 1=FS in sync
                |||!+------------ TFS 0=no, 1=required
                |||+============= RFS width 0=FS before data, 1=FS in sync
                ||+-------------- RFS 0=no, 1=required
                |+--------------- ISCLK 0=ext, 1=int
                +---------------- multichannel 0=disable, 1=enable
            }


        ax0 = b#0000000000000111;   dm (SPORT0_TX_Channels0) = ax0;
            {   ^15          00^   transmit word enables: channel # == bit # }
        ax0 = b#0000000000000111;   dm (SPORT0_TX_Channels1) = ax0;
            {   ^31          16^   transmit word enables: channel # == bit # }
        ax0 = b#0000000000000111;   dm (SPORT0_RX_Channels0) = ax0;
            {   ^15          00^   receive word enables: channel # == bit # }
        ax0 = b#0000000000000111;   dm (SPORT0_RX_Channels1) = ax0;
            {   ^31          16^   receive word enables: channel # == bit # }


{============== S Y S T E M   A N D   M E M O R Y   S T U F F ==============}
        ax0 = b#0000111111111111;   dm (DM_Wait_Reg) = ax0;
            {   |+-/+-/+-/+-/+-/- ! IOWAIT0
                ||  |  !  |       !
                ||  |  !  |       !
                ||  |  !  +------ | IOWAIT1
                ||  |  !          |
                ||  |  !          |
                ||  |  +--------- ! IOWAIT2
                ||  |             !
                ||  |             !
                ||  +------------ | IOWAIT3
                ||                |
                ||                |
                |+=============== ! DWAIT
                |                 !
                |                 !
                +---------------- 0
            }

        ax0 = b#0001000000000000;   dm (System_Control_Reg) = ax0;
            {   +-/!||+-----/+-/- | program memory wait states
                |  !|||           | 0
                |  !|||           |
                |  !||+---------- 0
                |  !||            0
                |  !||            0
                |  !||            0
                |  !||            0
                |  !||            0
                |  !||            0
                |  !|+----------- SPORT1 1=serial port, 0=FI, FO, IRQ0, IRQ1,..
                |  !+------------ SPORT1 1=enabled, 0=disabled
                |  +============= SPORT0 1=enabled, 0=disabled
                +---------------- 0
                                  0
                                  0
            }



        ifc = b#00000011111111;         { clear pending interrupt }
        nop;


        icntl = b#00000;
            {     ||||+- | IRQ0: 0=level, 1=edge
                  |||+-- | IRQ1: 0=level, 1=edge
                  ||+--- | IRQ2: 0=level, 1=edge
                  |+---- 0
                  |----- | IRQ nesting: 0=disabled, 1=enabled
            }


        mstat = b#1000000;
            {     ||||||+- | Data register bank select
                  |||||+-- | FFT bit reverse mode (DAG1)
                  ||||+--- | ALU overflow latch mode, 1=sticky
                  |||+---- | AR saturation mode, 1=saturate, 0=wrap
                  ||+----- | MAC result, 0=fractional, 1=integer
                  |+------ | timer enable
                  +------- | GO MODE
            }



{******************************************************************************
 *
 *  ADSP 1847 Codec intialization
 *
 ******************************************************************************}

        {   clear flag }
        ax0 = 1;
        dm(stat_flag) = ax0;

        {   enable transmit interrupt }
        imask = b#0001000000;
            {     |||||||||+ | timer
                  ||||||||+- | SPORT1 rec or IRQ0
                  |||||||+-- | SPORT1 trx or IRQ1
                  ||||||+--- | BDMA
                  |||||+---- | IRQE
                  ||||+----- | SPORT0 rec
                  |||+------ | SPORT0 trx
                  ||+------- | IRQL0
                  |+-------- | IRQL1
                  +--------- | IRQ2
            }


        ax0 = dm (i1, m1);          { start interrupt }
        tx0 = ax0;

check_init:
        ax0 = dm (stat_flag);       { wait for entire init }
        af = pass ax0;              { buffer to be sent to }
        if ne jump check_init;      { the codec            }

        ay0 = 2;
check_aci1:
        ax0 = dm (rx_buf);          { once initialized, wait for codec }
        ar = ax0 and ay0;           { to come out of autocalibration }
        if eq jump check_aci1;      { wait for bit set }

check_aci2:
        ax0 = dm (rx_buf);          { wait for bit clear }
        ar = ax0 and ay0;
        if ne jump check_aci2;
        idle;

        ay0 = 0xbf3f;               { unmute left DAC }
        ax0 = dm (init_cmds + 6);
        ar = ax0 AND ay0;
        dm (tx_buf) = ar;
        idle;

        ax0 = dm (init_cmds + 7);   { unmute right DAC }
        ar = ax0 AND ay0;
        dm (tx_buf) = ar;
        idle;


        ifc = b#00000011111111;     { clear any pending interrupt }
        nop;

        imask = b#0000110000;       { enable rx0 interrupt }
            {     |||||||||+ | timer
                  ||||||||+- | SPORT1 rec or IRQ0
                  |||||||+-- | SPORT1 trx or IRQ1
                  ||||||+--- | BDMA
                  |||||+---- | IRQE
                  ||||+----- | SPORT0 rec
                  |||+------ | SPORT0 trx
                  ||+------- | IRQL0
                  |+-------- | IRQL1
                  +--------- | IRQ2
            }



{------------------------------------------------------------------------------
 -
 -  wait for interrupt and loop forever
 -
 ------------------------------------------------------------------------------}

        ax0=0;
        dm(stat_flag)=ax0;





            {*---------------- LAB_TDS ------------------ *}

      ar=0xFFFF; { Poner 16 unos en ar}
      sr = ashift ar by 10 (hi); {Crear una m scara binaria para         }
                                   {eliminar los bits menos significativos }

        ay0 =  sr1;                {Guardar la masc en ay0 para hacer el
                                   {AND con las muestras}
{----------------------------------------------------------------------}




talkthru:       idle;
        ar = dm(stat_flag);
        ar = pass ar;
        if ne rts;
        jump talkthru;




{******************************************************************************
 *
 *  Interrupt service routines
 *
 ******************************************************************************}



{------------------------------------------------------------------------------
 -
 -  transmit interrupt used for Codec initialization
 -
 ------------------------------------------------------------------------------}
next_cmd:
 {       ena sec_reg;}
        ax0 = dm (i3, m1);          { fetch next control word and }
        dm (tx_buf) = ax0;          { place in transmit slot 0    }
        ax0 = i3;
        ay0 = ^init_cmds;
        ar = ax0 - ay0;
        if gt rti;                  { rti if more control words still waiting }
        ax0 = 0xaf00;               { else set done flag and }
        dm (tx_buf) = ax0;          { remove MCE if done initialization }
        ax0 = 0;
        dm (stat_flag) = ax0;       { reset status flag }
        rti;


irqe:   toggle fl1;
        rti;




{----------------------------------------------------------------------
 -                           * LAB_TDS *
 -  LO QUE SE EJECUTA CADA VEZ QUE LLEGA UNA MUESTRA
 --------------------------------------------------------------------}


input_samples:
        i2=^q1q2;					{reinicializo los buffers al principio}
        i5=^coefs;
		
		ay0= dm (cambia);
		ar= - ay0;					{Hace oscilar el valor del num marcado}
		dm (cambia) =ar;			{ya que la placa no saca continua}
		
		dm(tx_buf +1) = ar;			{saca el valor por el canal izquierdo}

decN:
	ay0=dm(contaN);
	ar=ay0-1;
	dm(contaN)=ar;
	if lt jump salta_entrada;

	
entrada:
	mx0 = dm (rx_buf + 1);
	my0=dm(ganancia);
	mr=mx0*my0(ss);
	ay1=mr1;
	
	cntr=tonos;							{Repetimos para cada tono}
	do parte1 until ce;
		mx0=dm(i2,m1); 
		my0=dm(i5,m4);		{Cargamos q1 y coeficiente}
		mr=mx0*my0(ss), ay0=dm(i2,m3);		{q1*coef, obtener q2}

		my0=1;				
		mr=mr1*my0(ss);		{q1*2*cos(alpha)}	
	
		ar=mr0-ay0;							{q1*2*coef - q2}
		ar=ar+ay1;							{q1*2*coef - q2 + entrada}
		dm(i2,m1)=ar;						{suma -> q1}
	parte1:	dm(i2,m1)=mx0;					{q1 -> q2}
	
	
	rti;
	

salta_entrada:
	call finalizar;
	call salida;
	call reinit;
	rti;
	
finalizar:

	i4=^sqr;
	i2=^q1q2;
	i5=^coefs;	
	
	cntr=tonos;
	do cuadrados until ce;
		ar=dm(i5,m4);					{Obtener Coef}
		my0=1;
		mr=ar*my0(ss);
		ar=mr0;							{coef * 2}
		
		mx0=dm(i2,m1);					{Obtener q1 dos veces}
		my0=mx0;
		
		mx1=dm(i2,m1);					{Obtener q2 dos veces}
		my1=mx1;
		
		
		
		mr=0;
		mf=mx0*my1(ss);					{q1*q2}
		mr=mr-ar*mf(ss);				{-q1*q2*coef}
		mr=0;
		mr=mr+mx0*my0(ss);				{q1^2   -q1*q2*coef } 
		mr=mr+mx1*my1(ss);				{q2^2 + q1^2   -q1*q2*coef}
		
	cuadrados: dm(i4,m4)=mr1; 
	
	rts;


salida:
	ay0=dm(umbral);
	mx0=0;
	
	ax0=dm(sqr);
	ar=ax0 - ay0;
	if ge jump fila0;
	ax0=dm(sqr+1);
	ar=ax0 - ay0;
	if ge jump fila1;
	ax0=dm(sqr+2);
	ar=ax0 - ay0;
	if ge jump fila2;
	ax0=dm(sqr+3);
	ar=ax0 - ay0;
	if ge jump fila3;
	mx0=0;
	jump sacaresul;
	rts;
	
fila0:
	ax0=dm(sqr+4);
	ar=ax0 - ay0;
	mx0=6400;						{Nivel a sacar para '1'}
	if ge jump sacaresul;
	ax0=dm(sqr+5);
	ar=ax0 - ay0;
	mx0=9600;						{Nivel a sacar para '2'}
	if ge jump sacaresul;
	ax0=dm(sqr+6);
	ar=ax0 - ay0;
	mx0=12800;						{Nivel a sacar para '3'}
	if ge jump sacaresul;
	ax0=dm(sqr+7);
	ar=ax0 - ay0;
	mx0=0;
	if ge jump sacaresul;
	
	mx0=0;
	jump sacaresul;

	
fila1:
	ax0=dm(sqr+4);
	ar=ax0 - ay0;
	mx0=16000;						{Nivel a sacar para '4'}
	if ge  jump sacaresul;
	ax0=dm(sqr+5);
	ar=ax0 - ay0;
	mx0=19200;						{Nivel a sacar para '5'}
	if ge jump sacaresul;
	ax0=dm(sqr+6);
	ar=ax0 - ay0;
	mx0=22400;						{Nivel a sacar para '6'}
	if ge jump sacaresul;
	ax0=dm(sqr+7);
	ar=ax0 - ay0;
	mx0=0;
	if ge jump sacaresul;
	
	mx0=0;
	jump sacaresul;
	
	
fila2:
	ax0=dm(sqr+4);
	ar=ax0 - ay0;
	mx0=25600;						{Nivel a sacar para '7'}
	if ge jump sacaresul;
	ax0=dm(sqr+5);
	ar=ax0 - ay0;
	mx0=28800;						{Nivel a sacar para '8'}
	if ge jump sacaresul;
	ax0=dm(sqr+6);
	ar=ax0 - ay0;
	mx0=32000;						{Nivel a sacar para '9'}
	if ge jump sacaresul;
	ax0=dm(sqr+7);
	ar=ax0 - ay0;
	mx0=0;
	if ge jump sacaresul;
	
	
	mx0=0;
	jump sacaresul;
	
fila3:
	ax0=dm(sqr+4);
	ar=ax0 - ay0;
	mx0=0;
	if ge jump sacaresul;
	ax0=dm(sqr+5);
	ar=ax0 - ay0;
	mx0=3200;						{Nivel a sacar para '0'}
	if ge jump sacaresul;
	ax0=dm(sqr+6);
	ar=ax0 - ay0;
	mx0=0;
	if ge jump sacaresul;
	ax0=dm(sqr+7);
	ar=ax0 - ay0;
	mx0=0;
	if ge jump sacaresul;
	
	mx0=0;
	jump sacaresul;
	
sacaresul:	dm(cambia)=mx0;
	rts;
	
apagado:
	reset fl1;
	mx0=0;
	dm(cambia)=mx0;
	rts;
	
	
reinit:
	i2=^q1q2;
    i4=^sqr;
	cntr=tonos_2;
	do borra until ce;
	dm(i4,m4)=0;
borra: dm(i2,m1)=0;
	ax0=N;
	dm(contaN)=ax0;
	rts;
	


.endmod;
