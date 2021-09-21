; Archivo: Proyecto 1
; Dispositivo: PIC16F887
; Autor: José Santizo 
; Compilador: pic-as (v2.32), MPLAB X v5.50
    
; Programa: Reloj digital
; Hardware: Displays de 7 segmentos, LEDs y pushbuttons
    
; Creado: 14 de septiembre, 2021
; Última modificación: 19 de septiembre, 2021
    
PROCESSOR 16F887
#include <xc.inc>
    
;configuration word 1
 CONFIG FOSC=INTRC_NOCLKOUT // Oscilador interno sin salidas
 CONFIG WDTE=OFF            // WDT desabilitado (reinicio repetitiv del PIC)
 CONFIG PWRTE=OFF            // PWRTE habilitado (espera de 72 ms al iniciar)
 CONFIG MCLRE=OFF           // El pin de MCLR se utiliza como prendido o apagado
 CONFIG CP=OFF              // Sin protecci?n de c?digo
 CONFIG CPD=OFF		    // Sin protecci?n de datos 
 
 CONFIG BOREN=OFF	    // Sin reinicio cuando el voltaje de alimentaci?n baja de 4V
 CONFIG IESO=OFF	    // Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF	    // Cambio de reloj externo a interno en caso de fallo
 CONFIG LVP=OFF		    // Programaci?n en bajo voltaje permitido
 
;configuration word 2
 CONFIG WRT=OFF		    // Protecci?n de autoescritura por el programa desactivada
 CONFIG BOR4V=BOR40V	    // Reinicio abajo de 4v, (BOR21V = 2.1V)
 
;-----------------------------------------
;		 MACROS
;-----------------------------------------  
 REINICIAR_TMR1 MACRO
    MOVLW	12			    ;Timer 1 en 500 ms
    MOVWF	TMR1H
    MOVLW	42		
    MOVWF	TMR1L
    BCF		TMR1IF
    ENDM
 
 REINICIAR_TMR0 MACRO
    BANKSEL	PORTD
    MOVLW	100			    ; Timer 0 para que incremento cada 5 milisegundos
    MOVWF	TMR0			    
    BCF		T0IF			    
    ENDM 
    
 REINICIAR_TMR2 MACRO
    BANKSEL	PORTA			    ;Reiniciar la bandera del timer 2
    BCF		TMR2IF
    ENDM
    
 WDIV1 MACRO	DIVISOR,COCIENTE,RESIDUO    ; Macro de divisor
    MOVWF	CONTEO			    ; El dividendo se encuentra en W, pasar w a conteo
    CLRF	CONTEO1			    ; Se limpia la variables en W
	
    INCF	CONTEO1			    ; Aumentar conteo en 1 que servira como el cociente
    MOVLW	DIVISOR			    ; Pasar el divisor a w
	
    SUBWF	CONTEO, F		    ; Restar w - conteo
    BTFSC	STATUS,0		    ; Si se prende el bit de carry, se decrementa conteo en 1
    GOTO	$-4
	
    DECF	CONTEO1, W		    
    MOVWF	COCIENTE		    ; Mover 1 de los dígitos a cociente
	
    MOVLW	DIVISOR			    
    ADDWF	CONTEO,W
    MOVWF	RESIDUO			    ; Mover el otro dígito a residuo
  endm
 
;Variables a utilizar
 PSECT udata_bank0	; common memory
    STATUS_MODO:	    DS 1
    OLD_STATUS_MODO:	    DS 1
    STATUS_SEL:		    DS 1
    OLD_STATUS_SEL:	    DS 1
    STATUS_SET:		    DS 1
    OLD_STATUS_SET:	    DS 1
    UNO:		    DS 1
    DIEZ:		    DS 1
    CIEN:		    DS 1
    MIL:		    DS 1
    DISP_SELECTOR:	    DS 1
    UNI:		    DS 1
    DECE:		    DS 1
    CEN:		    DS 1
    MILE:		    DS 1
    UNI_TEMP:		    DS 1
    DECE_TEMP:		    DS 1
    CEN_TEMP:		    DS 1
    MILE_TEMP:		    DS 1
    UNI1:		    DS 1
    DECE1:		    DS 1
    CEN1:		    DS 1
    MILE1:		    DS 1
    UNI_TEMP1:		    DS 1
    DECE_TEMP1:		    DS 1
    CEN_TEMP1:		    DS 1
    MILE_TEMP1:		    DS 1
    SEGUNDOS:		    DS 1
    MINUTOS:		    DS 1
    HORAS:		    DS 1
    DIAS:		    DS 1
    MESES:		    DS 1
    LIMITE_DIAS:	    DS 1
    CONTEO:		    DS 1
    CONTEO1:		    DS 1
    LUCES:		    DS 1
    AND1:		    DS 1
    AND2:		    DS 1
    AND3:		    DS 1
    AND4:		    DS 1
    STATUS_SEL_TEMP:	    DS 1
    STATUS_MODO_TEMP:	    DS 1
    COM_STATUS_SEL_TEMP:    DS 1
    COM_STATUS_MODO_TEMP:   DS 1
    CONT:		    DS 2
    CONT1:		    DS 1
  
 PSECT udata_shr	; common memory
    W_TEMP:		    DS 1	    ; 1 byte
    STATUS_TEMP:	    DS 1	    ; 1 byte
    
    
 PSECT resVect, class=CODE, abs, delta=2
 ;------------vector reset-----------------
 ORG 00h				    ; posición 0000h para el reset
 resetVec:
    PAGESEL MAIN
    goto MAIN

 PSECT intVect, class=CODE, abs, delta=2
 ;------------vector interrupciones-----------------
 ORG 04h				    ; posici?n 0000h para interrupciones
 
 PUSH:
    MOVWF	W_TEMP
    SWAPF	STATUS, W
    MOVWF	STATUS_TEMP
 
 ISR:
    BTFSC	T0IF			    ;Si la bandera del timer 0 se activa
    CALL	INT_TMR0		    ;entonces ejecutar la interrupción del timer 0
    
    BTFSC	TMR2IF			    ;Si la bandera del timer 2 se activa
    CALL	CONTADORES_HORA		    ;entonces ejecutar los contadores de las horas y meses
    
    BTFSC	TMR1IF			    ;Si la bandera del timer 1 se activa
    CALL	LUCES_HORA		    ;entonces prender las luces cada 500 ms del reloj
 POP:
    SWAPF	STATUS_TEMP, W
    MOVWF	STATUS
    SWAPF	W_TEMP, F
    SWAPF	W_TEMP, W
    RETFIE
   
 ;------------Sub rutinas de interrupci?n--------------
 LUCES_HORA:
    REINICIAR_TMR1			    ;Reiniciar el contador del timer 1
    BTFSC	STATUS_MODO, 0		    ;Si estamos en el modo de hora
    CALL	INTERMITENCIA		    ;entonces ejecutar la intermitencia de las luces de enmedio
    RETURN
    
 INTERMITENCIA:
    INCF	LUCES			    ;Incrementar el contador llamado luces
    MOVF	LUCES, W		    
    ANDLW	00000001B		    ;Realizar un and con el número 1
    MOVWF	PORTE			    ;Mover el resultado al puerto E para lograr intermitencia en el bit 0 	
    RETURN
 
 CONTADORES_HORA:
    REINICIAR_TMR2			    ;Reiniciar el timer 2 en 5 ms
    INCF	CONT			    ;Incrementar variable CONT hasta que cuente 200
    MOVF	CONT, W
    SUBLW	200			    ;Cuando cuente 200, va a haber pasado 1 segundo
    BTFSS	STATUS, 2		    ;Si CONT = 0
    GOTO	RETURN_T2		    ;	entonces limpiar variable CONT y comenzar la cuenta otra vez
    CLRF	CONT
    
    BTFSS	STATUS_SET, 0		    ;Chequear si estamos en modo SET
    INCF	SEGUNDOS		    ;Si SET = 1, entonces incrementar segundos
    
    MOVF	SEGUNDOS, W		    ;Si SEGUNDOS = 60
    SUBLW	60			    ; entonces Llamar subrutina INC_MINUTOS	
    BTFSC	STATUS, 2
    CALL	INC_MINUTOS
    
    MOVF	MINUTOS, W		    ;Si MINUTOS = 60
    SUBLW	60			    ; entonces llamar a subrutina INC_HORAS
    BTFSC	STATUS, 2
    CALL	INC_HORAS
    
    MOVF	HORAS, W		    ;Si HORAS = 24
    SUBLW	24			    ; entonces llamar a subrutina INC_DIAS
    BTFSC	STATUS, 2
    CALL	INC_DIAS
    
    MOVF	MESES, W		    ;Dependiendo el número de mes, retornar
    CALL	TABLA_FECHA		    ;el límite de días que contiene este y guardarlo
    MOVWF	LIMITE_DIAS		    ;en la variable LIMITE_DIAS
    
    MOVF	DIAS, W			    ;Si DIAS = LIMITE_DIAS
    SUBWF	LIMITE_DIAS, W		    ; entonces llamar a subrutina INC_MES
    BTFSC	STATUS, 2
    CALL	INC_MES
    
    MOVF	MESES, W		    ;Si MESES = 13
    SUBLW	13			    ; entonces llamar a la subrutina REINICIO
    BTFSC	STATUS, 2
    CALL	REINICIO
    
    RETURN
    
 RETURN_T2:
    RETURN				    ;Subrutina para generar un return en la subrutina de CONTADORES_HORA

 INC_MINUTOS:
    INCF	MINUTOS			    ;Incrementar MINUTOS y reiniciar contador SEGUNDOS
    CLRF	SEGUNDOS
    RETURN
    
 INC_HORAS:
    INCF	HORAS			    ;Incrementar HORAS y reiniciar contador MINUTOS
    CLRF	MINUTOS
    RETURN
    
 INC_DIAS:
    INCF	DIAS			    ;Incrementar DIAS y reiniciar contador HORAS
    CLRF	HORAS	    
    RETURN
    
 INC_MES:
    INCF	MESES			    ;Incrementar MESES y comenzar contador de DIAS en 1 ya que no existe día 0
    MOVLW	1
    MOVWF	DIAS
    RETURN   
 
 REINICIO:
    MOVLW	1			    ;Comenzar contador de MESES en 1 ya que no existe mes 0
    MOVWF	MESES
    RETURN
    
 INT_TMR0:
    REINICIAR_TMR0			    ;Reiniciar TMR0 cada 5 ms    
    
    ; SE SELECCIONA EL DISPLAY AL QUE SE DESEA ESCRIBIR
    MOVF	DISP_SELECTOR, W	    ;W = DISP_SELECTOR
    MOVWF	PORTD			    ;PORTD = DISP_SELECTOR
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE UNIDADES (0001)
    MOVF	DISP_SELECTOR, W
    SUBLW	1			    ;Chequear si DISP_SELECTOR = 0001
    BTFSC	STATUS, 2
    CALL	DISPLAY_UNI		
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE DECENAS (0010)
    MOVF	DISP_SELECTOR, W
    SUBLW	2			    ;Chequear si DISP_SELECTOR = 0010
    BTFSC	STATUS, 2
    CALL	DISPLAY_DECE		
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE CENTENAS (0100)
    MOVF	DISP_SELECTOR, W
    SUBLW	4			    ;Chequear si DISP_SELECTOR = 0100
    BTFSC	STATUS, 2
    CALL	DISPLAY_CEN
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE MILESIMAS (1000)
    MOVF	DISP_SELECTOR, W
    SUBLW	8			    ;Chequear si DISP_SELECTOR = 1000
    BTFSC	STATUS, 2
    CALL	DISPLAY_MIL
    
    ;MOVER EL 1 EN DISP_SELECTOR 1 POSICI?N A LA IZQUIERDA
    BCF		STATUS, 0		    ;Se limpia el bit de carry
    RLF		DISP_SELECTOR, 1	    ;1 en DISP_SELECTOR se corre una posición a al izquierda
    
    ;REINICIAR DISP_SELECTOR SI EL VALOR SUPER? EL N?MERO DE DISPLAYS
    MOVF	DISP_SELECTOR, W	    ;Chequear si DISP_SELECTOR = 10000
    SUBLW	16			    ; entonces llamar a subrutina RESET_DISP_SELECTOR
    BTFSC	STATUS, 2
    CALL	RESET_DISP_SELECTOR
    
    RETURN
    
 DISPLAY_UNI:
    MOVF	UNO, W			    ;W = UN0
    MOVWF	PORTA			    ;PORTA = W
    RETURN
    
 DISPLAY_DECE:
    MOVF	DIEZ, W			    ;W = DIEZ
    MOVWF	PORTA			    ;PORTA = W
    RETURN
    
 DISPLAY_CEN:
    MOVF	CIEN, W			    ;W = CIEN
    MOVWF	PORTA			    ;PORTA = W
    RETURN
    
 DISPLAY_MIL:
    MOVF	MIL, W			    ;W = MIL
    MOVWF	PORTA			    ;PORTA = W
    RETURN

 RESET_DISP_SELECTOR:
    CLRF	DISP_SELECTOR		    ;DISP_SELECTOR = 0
    INCF	DISP_SELECTOR, 1	    ;Incrementar DISP_SELECTOR en 1 para que comience en 0001 otra vez
    RETURN
    
  
 ;------------Posici?n del c?digo---------------------
 PSECT CODE, DELTA=2, ABS
 ORG 100H		;Posici?n para el codigo
 
 ;-------------Tabla n?meros--------------------------
 TABLA_FECHA:
    CLRF	PCLATH
    BSF		PCLATH, 0   ;PCLATH = 01    PCL = 02
    ANDLW	0x0f
    ADDWF	PCL	    ;PC = PCLATH + PCL + W
    
    ;Verificar el límite de días dependiendo de cada mes
    RETLW	0	    ;MES INICIAL 0 para evitar errores
    RETLW	32	    ;ENERO
    RETLW	29	    ;FEBRERO
    RETLW	32	    ;MARZO
    RETLW	31	    ;ABRIL
    RETLW	32	    ;MAYO
    RETLW	31	    ;JUNIO
    RETLW	32	    ;JULIO
    RETLW	32	    ;AGOSTO
    RETLW	31	    ;SEPTIEMBRE
    RETLW	32	    ;OCTUBRE
    RETLW	31	    ;NOVIEMBRE
    RETLW	32	    ;DICIEMBRE
 
 TABLA:
    CLRF	PCLATH
    BSF		PCLATH, 0   ;PCLATH = 01    PCL = 02
    ANDLW	0x0f
    ADDWF	PCL	    ;PC = PCLATH + PCL + W
    RETLW	00111111B   ;0
    RETLW	00000110B   ;1
    RETLW	01011011B   ;2
    RETLW	01001111B   ;3
    RETLW	01100110B   ;4
    RETLW	01101101B   ;5
    RETLW	01111101B   ;6
    RETLW	00000111B   ;7
    RETLW	01111111B   ;8
    RETLW	01101111B   ;9
    RETLW	01110111B   ;A
    RETLW	01111100B   ;B
    RETLW	00111001B   ;C
    RETLW	01011110B   ;D
    RETLW	01111001B   ;E
    RETLW	01110001B   ;F
    
 ;-----------Configuraci?n----------------
 MAIN:
    BSF		STATUS_MODO, 0		    ;Configurar inicialmente el STATUS_MODO en 1
    BCF		STATUS_SET, 0		    ;Configurar inicialmente el STATUS_SET en 0
    BCF		STATUS_SEL, 0		    ;Configurar inicialmente el STATUS_SEL en 0
    CALL	RESET_DISP_SELECTOR	    ;Reiniciar el DISPLAYS_SELECTOR para que sea 0001
    CALL	CONFIG_IO		    ;Configuración de entradas y salidas del PIC
    CALL	CONFIG_RELOJ		    ;Configuración del oscilador
    CALL	CONFIG_TMR0		    ;Configuración del Timer 0
    CALL	CONFIG_INT_ENABLE	    ;Configuración de interrupciones
    CALL	CONFIG_TMR2		    ;Configuración del Timer 2
    CALL	CONFIG_TMR1		    ;Configuración del Timer 1
    BANKSEL	PORTA
    BANKSEL	PORTD
    
 ;---------Loop principal----------------
 LOOP:
    CALL	LIMITES_MINUTOS_HORAS	    ;Llamar a LIMITES_MINUTOS_HORAS
    CALL	LIMITES_MESES_DIAS	    ;Llamar a LIMITES_MESES_DIAS
    
    BTFSC	PORTB, 0		    ;Chequear si el bit 0 del PORTB está presionado
    CALL	ANTIREBOTE_MODO		    ; entonces llamar al antirebote del cambio de modo
    
    CALL	CHECK_MODO		    ;Llamar a CHECK_MODO
    
    BTFSC	PORTB, 1		    ;Chequear si el bit 1 del PORTB está presionado 
    CALL	ANTIREBOTE_SET		    ; entonces llamar al antirebote del cambio de modo de SET
    
    BTFSC	STATUS_SET, 0		    ;Chequear si nos encontramo en modo SET (STATUS_SET = 1)
    CALL	ANTIREBOTE_SEL		    ; entonces llamar al antirebote del cambio de selección de displays
    
    
    GOTO	LOOP			    ;Loop infinito
 
 ;---------------SUBRUTINAS------------------ 
 ;-----------------------------------------
 ;	 L?GICA DE CONTADORES DE HORA
 ;----------------------------------------- 
 LIMITES_MINUTOS_HORAS:
    MOVF	MINUTOS, W		    ;MINUTOS = W
    WDIV1	10,DECE,UNI		    ;Decenas de MINUTOS = DECE y unidades de MINUTOS = UNI
    
    MOVF	HORAS, W		    ;HORAS = W
    WDIV1	10,MILE,CEN		    ;Decenas de HORAS = MILE y unidades de HORAS = CEN
    
    MOVF	UNI, W			    ;UNI = W
    CALL	TABLA			    ;Traducir valor de W en tabla
    MOVWF	UNI_TEMP		    ;W traducido = UNI_TEMP
    
    MOVF	DECE, W			    ;DECE = W
    CALL	TABLA			    ;Traducir valor de W en tabla
    MOVWF	DECE_TEMP		    ;W traducido = DECE_TEMP
	    
    MOVF    	CEN, W			    ;CEN = W
    CALL	TABLA			    ;Traducir valor de W en tabla
    MOVWF	CEN_TEMP		    ;W traducido = CEN_TEMP
    
    MOVF	MILE, W			    ;MILE = W
    CALL	TABLA			    ;Traducir valor de W en tabla
    MOVWF	MILE_TEMP		    ;W traducido = MILE_TEMP
    RETURN
    
 ;-----------------------------------------
 ;	 LÓGICA DE CONTADORES DE FECHA
 ;----------------------------------------- 
 LIMITES_MESES_DIAS:
    MOVF	DIAS, W			    ;DIAS = W
    WDIV1	10,DECE1,UNI1		    ;Decenas de DIAS = DECE1 y unidades de DIAS = UNI1
    
    MOVF	MESES, W		    ;MESES = W
    WDIV1	10,MILE1,CEN1		    ;Decenas de MESES = MILE1 y unidades de MESES = CEN1
    
    MOVF	UNI1, W			    ;UNI1 = W
    CALL	TABLA			    ;Traducir valor de W en tabla
    MOVWF	UNI_TEMP1		    ;W traducido = UNI_TEMP1
    
    MOVF	DECE1, W		    ;DECE1 = W
    CALL	TABLA			    ;Traducir valor de W en tabla
    MOVWF	DECE_TEMP1		    ;W traducido = DECE_TEMP1
    
    MOVF	CEN1, W			    ;CEN1 = W
    CALL	TABLA			    ;Traducir valor de W en tabla
    MOVWF	CEN_TEMP1		    ;W traducido = CEN_TEMP1
    
    MOVF	MILE1, W		    ;MILE1 = W
    CALL	TABLA			    ;Traducir valor de W en tabla
    MOVWF	MILE_TEMP1		    ;W traducido = MILE_TEMP1
    RETURN  
 
 ;-----------------------------------------
 ;	       STATUS DE SET
 ;----------------------------------------- 
 ANTIREBOTE_SET:
    BTFSC	PORTB, 1		    ;Si bit 1 de PORTB = 0
    GOTO	$-1			    ; entonces llamara  subrutina FLIP_FLOP_SET
    CALL	FLIP_FLOP_SET
    RETURN
 
 FLIP_FLOP_SET:
    MOVF	STATUS_SET, W		    ;STATUS_SET = W
    MOVWF	OLD_STATUS_SET		    ;W = OLD_STATUS_SET
    
    BTFSC	OLD_STATUS_SET, 0	    ;Si OLD_STATUS_SET = 1
    CALL	LIMPIAR_CONT_UNI	    ; entonces llamar a LIMPIAR_CONT_UNI
    
    BTFSS	OLD_STATUS_SET, 0	    ;Si OLD_STATUS_SET = 0
    CALL	RESUME			    ; entonces llamar a RESUME
    
    RETURN
    
 LIMPIAR_CONT_UNI:
    BCF		STATUS_SET, 0		    ;STATUS_SET = 0
    CLRF	SEGUNDOS		    ;Limpiar contador de SEGUNDOS
    BCF		PORTC, 0		    ;Bit 0 de PORTC = 0
    BCF		PORTC, 4		    ;PORTC,4 = 0
    BCF		PORTC, 5		    ;PORTC,5 = 0
    RETURN
    
 RESUME:
    BSF		STATUS_SET, 0		    ;STATUS_SET = 1
    BSF		PORTC, 0		    ;Bit 1 de PORTC = 1
    RETURN
    
 ;-----------------------------------------
 ;	    STATUS DE SELECCIÓN
 ;----------------------------------------- 
 ANTIREBOTE_SEL:
    BTFSC	PORTB, 2		    ;Si bit 2 de PORTB = 1
    CALL	FLIP_FLOP_SEL		    ; entonces llamar a FLIP_FLOP_SEL
    
    CALL	AND_VERIFICACION1	    ;Verificaciones de límites en aumento de hora o fecha
    CALL	AND_VERIFICACION2
    CALL	AND_VERIFICACION3
    CALL	AND_VERIFICACION4
    RETURN
 
 FLIP_FLOP_SEL:
    BTFSC	PORTB, 2		    ;Si bit 2 de PORTB = 0
    GOTO	$-1			    
    MOVF	STATUS_SEL, W		    ; entonces STATUS_SEL = W	
    MOVWF	OLD_STATUS_SEL		    ; W = OLD_STATUS_SEL
    
    BTFSC	OLD_STATUS_SEL, 0	    ;Si OLD_STATUS_SEL = 1
    CALL	HORAS_DIAS		    ; entonces llamar a HORAS_DIAS
    
    BTFSS	OLD_STATUS_SEL, 0	    ;Si OLD_STATUS_SEL = 0
    CALL	MINUTOS_MES		    ; entonces llamar a MINUTOS_MES
    
    RETURN  
    
 MINUTOS_MES:
    BSF		STATUS_SEL, 0		    ;STATUS_SEL = 1
    BCF		PORTC, 4		    ;Bit 4 de PORTC = 1
    BSF		PORTC, 5		    ;Bit 5 de PORTC = 0
    RETURN
    
 HORAS_DIAS:
    BCF		STATUS_SEL, 0		    ;STATUS_SEL = 0
    BCF		PORTC, 5		    ;Bit 5 de PORTC = 1
    BSF		PORTC, 4		    ;Bit 4 de PORTC = 0
    RETURN
    
 AND_VERIFICACION1:
    MOVF	STATUS_SEL, W		    ;STATUS_SEL  = W
    MOVWF	STATUS_SEL_TEMP		    ;W = STATUS_SEL_TEMP
    MOVF	STATUS_MODO, W		    ;STATUS_MODO = W
    MOVWF	STATUS_MODO_TEMP	    ;W = STATUS_MODO_TEMP
    
    COMF	STATUS_SEL_TEMP, W	    ;Realizar '(STATUS_SEL_TEMP) and (STATUS_MODO_TEMP)
    ANDWF	STATUS_MODO_TEMP, W
    MOVWF	AND1			    ;Resultado de and = AND1
    BTFSC	AND1, 0			    ;Si AND1 = 1
    CALL	ANTIREBOTE_INTERNO3	    ; entonces llamar a ANTIREBOTE_INTERNO3
    RETURN
    
 AND_VERIFICACION2:
    MOVF	STATUS_SEL, W		    ;STATUS_SEL  = W
    MOVWF	STATUS_SEL_TEMP		    ;W = STATUS_SEL_TEMP
    MOVF	STATUS_MODO, W		    ;STATUS_MODO = W
    MOVWF	STATUS_MODO_TEMP	    ;W = STATUS_MODO_TEMP
    
    COMF	STATUS_MODO_TEMP, W	    ;Realizar (STATUS_SEL_TEMP) and '(STATUS_MODO_TEMP)
    ANDWF	STATUS_SEL_TEMP, W
    MOVWF	AND2			    ;Resultado de and = AND2
    BTFSC	AND2, 0			    ;Si AND2 = 1
    CALL	ANTIREBOTE_INTERNO4	    ; entonces llamar a ANTIREBOTE_INTERNO4
    RETURN
    
 AND_VERIFICACION3:
    MOVF	STATUS_SEL, W		    ;STATUS_SEL  = W
    MOVWF	STATUS_SEL_TEMP		    ;W = STATUS_SEL_TEMP
    MOVF	STATUS_MODO, W		    ;STATUS_MODO = W
    MOVWF	STATUS_MODO_TEMP	    ;W = STATUS_MODO_TEMP
    
    MOVF	STATUS_MODO_TEMP	    ;Realizar (STATUS_SEL_TEMP) and (STATUS_MODO_TEMP)
    ANDWF	STATUS_SEL_TEMP, W
    MOVWF	AND3			    ;Resultado de and = AND3
    BTFSC	AND3, 0			    ;Si AND3 = 1
    CALL	ANTIREBOTE_INTERNO1	    ; entonces llamar a ANTIREBOTE_INTERNO1
    RETURN
    
 AND_VERIFICACION4:
    MOVF	STATUS_SEL, W		    ;STATUS_SEL  = W
    MOVWF	STATUS_SEL_TEMP		    ;W = STATUS_SEL_TEMP
    MOVF	STATUS_MODO, W		    ;STATUS_MODO = W
    MOVWF	STATUS_MODO_TEMP	    ;W = STATUS_MODO_TEMP
    
    COMF	STATUS_SEL_TEMP, W	    ;Realizar '(STATUS_SEL_TEMP) and '(STATUS_MODO_TEMP)
    MOVWF	COM_STATUS_SEL_TEMP
    COMF	STATUS_MODO_TEMP, W
    ANDWF	COM_STATUS_SEL_TEMP, W
    MOVWF	AND4			    ;Resultado de and = AND4
    BTFSC	AND4, 0			    ;Si AND4 = 1
    CALL	ANTIREBOTE_INTERNO2	    ; entonces llamar a ANTIREBOTE_INTERNO2
    RETURN
    
 ANTIREBOTE_INTERNO1:
    BTFSC	PORTB, 3		    ;Si PORTB, 3 = 1
    CALL	INCRE_MINUTOS		    ; entonces llamar INCRE_MINUTOS
    
    BTFSC	PORTB, 4		    ;Si PORTB, 4 = 1
    CALL	DECRE_MINUTOS		    ; entonces llamar DECRE_MINUTOS
    RETURN
    
 INCRE_MINUTOS:
    BTFSC	PORTB, 3		    ;Si PORTB,3 = 0
    GOTO	$-1			    ; entonces incrementar MINUTOS
    INCF	MINUTOS
    RETURN
    
 DECRE_MINUTOS:
    BTFSC	PORTB, 4		    ;Si PORTB,4 = 0
    GOTO	$-1			    ; entonces decrementar a MINUTOS
    DECF	MINUTOS
    
    MOVF	MINUTOS, W		    ;Si DECF MINUTOS = -1
    SUBLW	-1			    ; llamar a REINICIO3
    BTFSC	STATUS, 2
    CALL	REINICIO3
    RETURN
    
 REINICIO3:
    MOVLW	59			    ;Asignar 59 a MINUTOS
    MOVWF	MINUTOS
    RETURN
    
 ANTIREBOTE_INTERNO2:
    BTFSC	PORTB, 3		    ;Si PORTB,3 = 1
    CALL	INCRE_DIAS		    ; entonces llamar a INCRE_DIAS
	
    BTFSC	PORTB, 4		    ;Si PORTB,4 = 0
    CALL	DECRE_DIAS		    ; entonces llamar a DECRE_DIAS
    RETURN
    
 INCRE_DIAS:
    BTFSC	PORTB, 3		    ;Si PORTB,3 = 0
    GOTO	$-1			    ; entonces incrementar DIAS
    INCF	DIAS
    RETURN
    
 DECRE_DIAS:
    BTFSC	PORTB, 4		    ;Si PORTB,4 = 0
    GOTO	$-1			    ; entonces decrementar DIAS
    DECF	DIAS
    
    MOVF	DIAS, W			    ;Si DECF DIAS = -1
    SUBLW	-1			    ; entonces llamar a REINICIO2
    BTFSC	STATUS, 2
    CALL	REINICIO2
    RETURN
    
 REINICIO2:
    MOVF	LIMITE_DIAS		    ;LIMITE_DIAS = W
    MOVWF	DIAS			    ;W = DIAS
    RETURN
    
 ANTIREBOTE_INTERNO3:
    BTFSC	PORTB, 3		    ;Si PORTB,3 = 1
    CALL	INCRE_HORAS		    ; entonces llamar a INCRE_HORAS
    
    BTFSC	PORTB, 4		    ;Si PORTB,4 = 1
    CALL	DECRE_HORAS		    ; entonces llamar a DECRE_HORAS
    RETURN
    
 INCRE_HORAS:
    BTFSC	PORTB, 3		    ;Si PORTB,3 = 0
    GOTO	$-1			    ; entonces incrementar HORAS
    INCF	HORAS
    RETURN
    
 DECRE_HORAS:
    BTFSC	PORTB, 4		    ;Si PORTB,4 = 0
    GOTO	$-1			    ; entonces decrementar HORAS
    DECF	HORAS
    
    MOVF	HORAS, W		    ;Si DECF HORAS = -1
    SUBLW	-1			    ; entonces llamar a REINICIO1
    BTFSC	STATUS, 2
    CALL	REINICIO1
    RETURN
    
 REINICIO1:
    MOVLW	23			    ;Asignar 23 a HORAS
    MOVWF	HORAS
    RETURN
    
 ANTIREBOTE_INTERNO4:
    BTFSC	PORTB, 3		    ;Si PORTB,3 = 1
    CALL	INCRE_MESES		    ; entonces llamar a INCRE_MESES
    
    BTFSC	PORTB, 4		    ;Si PORTB,4 = 1
    CALL	DECRE_MESES		    ; entonces llamar a DECRE_MESES
    RETURN
    
 INCRE_MESES:
    BTFSC	PORTB, 3		    ;Si PORTB,3 = 0
    GOTO	$-1			    ;Incrementar Meses
    INCF	MESES
    RETURN
    
 DECRE_MESES:
    BTFSC	PORTB, 4		    ;Si PORTB,4 = 0
    GOTO	$-1			    ; entonces decrementar MESES
    DECF	MESES
    
    MOVF	MESES, W		    ;Si DECF MESES = -1
    SUBLW	-1			    ; entonces llamar a REINICIO4
    BTFSC	STATUS, 2
    CALL	REINICIO4
    RETURN
    
 REINICIO4:
    MOVLW	12			    ;Asignar 12 a MESES
    MOVWF	MESES
    RETURN
    
 ;-----------------------------------------
 ;	       STATUS DE MODO
 ;----------------------------------------- 
 ANTIREBOTE_MODO:
    BTFSC	PORTB, 0		    ;Si PORTB,0 = 0
    GOTO	$-1			    ; entonces llamar a FLIP_FLOP_GENERAL
    CALL	FLIP_FLOP_GENERAL	    ; o sino seguir chequeando PORBT,0
    RETURN
 
 FLIP_FLOP_GENERAL:
    MOVF	STATUS_MODO, W		    ;STATUS_MODO = W
    MOVWF	OLD_STATUS_MODO		    ;W = OLD_STATUS_MODO
    
    BTFSC	OLD_STATUS_MODO, 0	    ;Si OLD_STATUS_MODO = 1
    BCF		STATUS_MODO, 0		    ; entonces STATUS_MODO = 0
    
    BTFSS	OLD_STATUS_MODO, 0	    ;Si OLD_STATUS_MODO = 0
    BSF		STATUS_MODO, 0		    ; entonces STATUS_MODO = 1
    
    RETURN
    
 ;-----------------------------------------
 ;	       CHECK MODO
 ;----------------------------------------- 
 CHECK_MODO:
    BTFSC	STATUS_MODO, 0		    ;Si STATUS_MODO = 1
    CALL	HORA_DISPLAYS		    ; entonces llamar a HORA_DISPLAYS
    
    BTFSS	STATUS_MODO, 0		    ;Si STATUS_MODO = 0
    CALL	FECHA_DISPLAYS		    ; entonces llamar a FECHA_DISPLAYS
    RETURN
       
 HORA_DISPLAYS:
    MOVF	UNI_TEMP, W		    ;UNI_TEMP = W
    MOVWF	UNO			    ;W = UNO
    
    MOVF	DECE_TEMP, W		    ;DECE_TEMP = W
    MOVWF	DIEZ			    ;W = DIEZ
    
    MOVF	CEN_TEMP, W		    ;CEN_TEMP = W
    MOVWF	CIEN			    ;W = CIEN
    
    MOVF	MILE_TEMP, W		    ;MILE_TEMP = W
    MOVWF	MIL			    ;W = MIL
    
    RETURN
    
 FECHA_DISPLAYS:
    MOVF	UNI_TEMP1, W		    ;UNI_TEMP1 = W
    MOVWF	CIEN			    ;W = CIEN
    
    MOVF	DECE_TEMP1, W		    ;DECE_TEMP1 = W
    MOVWF	MIL			    ;W = MIL
    
    MOVF	CEN_TEMP1, W		    ;CEN_TEMP1 = W
    MOVWF	UNO			    ;W = UNO
    
    MOVF	MILE_TEMP1, W		    ;MILE_TEMP1 = W
    MOVWF	DIEZ			    ;W = DIEZ
    
    BSF		PORTE, 0		    ;PORTE,0 = 1
    
    RETURN
 ;-----------------------------------------
 ;      CONFIGURACIONES GENERALES
 ;----------------------------------------- 
 CONFIG_TMR2:
    BANKSEL	PORTA
    BCF		TOUTPS3
    BCF		TOUTPS2
    BCF		TOUTPS1
    BSF		TOUTPS0			    ;POSTCALER = 0001 = 1:2
    
    BSF		TMR2ON			    ;Activar TMR2
    
    BSF		T2CKPS1
    BCF		T2CKPS0			    ;PRESCALER = 1:16
    BANKSEL	TRISB
    MOVLW	156			    ;Reiniciar cada 5 ms
    MOVWF	PR2
    CLRF	TMR2
    REINICIAR_TMR2
    RETURN

 CONFIG_TMR1:
    BANKSEL	PORTC
    BCF		TMR1GE			    ;SIEMPRE CONTANDO
    BSF		T1CKPS1			    ;CONFIGURACIÓN DE PRESCALER
    BSF		T1CKPS0			    ;PRESCALER DE 1:8 - CADA 1 Hz
    BCF		T1OSCEN			    ;LOW POWER OSCILATOR OFF
    BCF		TMR1CS
    BSF		TMR1ON			    ;ENCENDER EL TMR1
    
    ;CARGAR LOS VALORES INICIALES
    REINICIAR_TMR1
    RETURN   
 
 CONFIG_INT_ENABLE:
    BANKSEL	TRISA
    BSF		TMR2IE			    ;INTERRUPCIÓN TMR2
    BSF		TMR1IE			    ;INTERRUPCIÓN TMR1
    
    BANKSEL	PORTA
    BSF		T0IE			    ;HABILITAR TMR0
    BCF		T0IF			    ;BANDERA DE TMR0
    
    BCF		TMR1IF			    ;BANDERA DE TMR1
    BCF		TMR2IF			    ;BANDERA DE TMR2
    
    BSF		PEIE			    ;INTERRUPCIONES PERIF?RICAS
    BSF		GIE			    ;INTERRUPCIONES GLOBALES
    RETURN

    
 CONFIG_TMR0:
    BANKSEL	TRISA
    BCF		T0CS		    ;Reloj interno
    BCF		PSA		    ;PRESCALER
    BSF		PS2 
    BSF		PS1
    BCF		PS0		    ;Prescaler = 110 = 1:128
    BANKSEL	PORTA
    REINICIAR_TMR0
    RETURN
 
 CONFIG_IO:
    BANKSEL	ANSEL
    CLRF	ANSEL		    ;Pines digitales
    CLRF	ANSELH
    
    BANKSEL	TRISA
    CLRF	TRISA		    ;PORT A como salida
    CLRF	TRISD		    ;PORT D como salida
    CLRF	TRISC		    ;PORT C como salida
    CLRF	TRISE		    ;PORT E como salida
    
    BSF		TRISB, 0	    ;PORT B, pin 0, 1, 2, 3 y 4 como entrada
    BSF		TRISB, 1
    BSF		TRISB, 2
    BSF		TRISB, 3
    BSF		TRISB, 4
    
    BANKSEL	PORTA
    CLRF	PORTA		    ;PORTA = 0
    CLRF	PORTD		    ;PORTD = 0
    CLRF	PORTC		    ;PORTC = 0
    CLRF	PORTE		    ;PORTE = 0
    RETURN
    
 CONFIG_RELOJ:
    BANKSEL	OSCCON
    BSF		IRCF2		    ;IRCF = 110 = 4MHz
    BSF		IRCF1
    BCF		IRCF0
    BSF		SCS		    ;Reloj interno
    RETURN
    
    
END


