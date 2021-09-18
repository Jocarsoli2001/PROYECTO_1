; Archivo: Proyecto 1
; Dispositivo: PIC16F887
; Autor: José Santizo 
; Compilador: pic-as (v2.32), MPLAB X v5.50
    
; Programa: Reloj digital
; Hardware: Displays de 7 segmentos, LEDs y pushbuttons
    
; Creado: 14 de septiembre, 2021
; Última modificación: 15 de septiembre, 2021
    
PROCESSOR 16F887
#include <xc.inc>
    
;configuration word 1
 CONFIG FOSC=INTRC_NOCLKOUT // Oscilador interno sin salidas
 CONFIG WDTE=OFF            // WDT desabilitado (reinicio repetitiv del PIC)
 CONFIG PWRTE=OFF            // PWRTE habilitado (espera de 72 ms al iniciar)
 CONFIG MCLRE=OFF           // El pin de MCLR se utiliza como prendido o apagado
 CONFIG CP=OFF              // Sin protección de código
 CONFIG CPD=OFF		    // Sin protección de datos 
 
 CONFIG BOREN=OFF	    // Sin reinicio cuando el voltaje de alimentación baja de 4V
 CONFIG IESO=OFF	    // Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF	    // Cambio de reloj externo a interno en caso de fallo
 CONFIG LVP=OFF		    // Programación en bajo voltaje permitido
 
;configuration word 2
 CONFIG WRT=OFF		    // Protección de autoescritura por el programa desactivada
 CONFIG BOR4V=BOR40V	    // Reinicio abajo de 4v, (BOR21V = 2.1V)
 
;-----------------------------------------
;		 MACROS
;-----------------------------------------  
 
 REINICIAR_TMR0 MACRO
    BANKSEL	PORTD
    MOVLW	254		; Timer 0 reinicia cada 2 ms
    MOVWF	TMR0		; Mover este valor al timer 0
    BCF		T0IF		; Limpiar la bandera del Timer 0
    ENDM 
 
;Variables a utilizar
 PSECT udata_bank0	; common memory
    STATUS_MODO:	    DS 1
    OLD_STATUS_MODO:	    DS 1
    UNO:		    DS 1
    DIEZ:		    DS 1
    CIEN:		    DS 1
    MIL:		    DS 1
    DISP_SELECTOR:	    DS 1
    UNI:		    DS 1
    DECE:		    DS 1
    CEN:		    DS 1
    MILE:		    DS 1
    CONT_UNI_MIN:	    DS 1
    CONT_DECE_MIN:	    DS 1
    CONT_UNI_HOR:	    DS 1
    CONT_DECE_HOR:	    DS 1
    CONT_UNI_DIA:	    DS 1
    CONT_DECE_DIA:	    DS 1
    CONT_UNI_MES:	    DS 1
    CONT_DECE_MES:	    DS 1
    CONT_UNI:		    DS 1
    UNI_MIN:		    DS 1
    DECE_MIN:		    DS 1
    UNI_HOR:		    DS 1
    DECE_HOR:		    DS 1
  
 PSECT udata_shr	; common memory
    W_TEMP:		    DS 1	; 1 byte
    STATUS_TEMP:	    DS 1	; 1 byte
    
    
 PSECT resVect, class=CODE, abs, delta=2
 ;------------vector reset-----------------
 ORG 00h		; posición 0000h para el reset
 resetVec:
    PAGESEL MAIN
    goto MAIN

 PSECT intVect, class=CODE, abs, delta=2
 ;------------vector interrupciones-----------------
 ORG 04h			    ; posición 0000h para interrupciones
 
 PUSH:
    MOVWF	W_TEMP
    SWAPF	STATUS, W
    MOVWF	STATUS_TEMP
 
 ISR:
    BTFSC	TMR2IF
    CALL	CONTADORES_HORA
    
    BTFSC	T0IF
    CALL	INT_TMR0
    
 POP:
    SWAPF	STATUS_TEMP, W
    MOVWF	STATUS
    SWAPF	W_TEMP, F
    SWAPF	W_TEMP, W
    RETFIE
   
 ;------------Sub rutinas de interrupción-------------- 
 CONTADORES_HORA:
    BCF		TMR2IF
    INCF	CONT_UNI		    ;INCREMENTAR EL CONTADOR GENERAL DE UNIDADES
    
    MOVF	CONT_UNI, W		    ; W = CONT_UNI 
    SUBLW	60			    ; 60 - CONT_UNI
    BTFSC	STATUS, 2		    ; IF (60-CONT_UNI = 0)
    CALL	INCREMENTO_UNI_MIN	    ; ENTONCES CALL INCREMENTO_DEC
    
    MOVF	CONT_UNI_MIN, W		    ; W = CONT_DECE
    SUBLW	10			    ; 10 - CONT_DECE
    BTFSC	STATUS, 2		    ; IF (10-CONT_DECE = 0)
    CALL	INCREMENTO_DECE_MIN	    ; ENTONCES CALL INCREMENTO_CEN
    
    MOVF	CONT_DECE_MIN, W	    ; W = CONT_DECE
    SUBLW	6			    ; 10 - CONT_DECE
    BTFSC	STATUS, 2		    ; IF (10-CONT_DECE = 0)
    CALL	INCREMENTO_UNI_HOR	    ; ENTONCES CALL INCREMENTO_CEN
    
    MOVF	CONT_UNI_HOR, W		    ; W = CONT_DECE
    SUBLW	10			    ; 10 - CONT_DECE
    BTFSC	STATUS, 2		    ; IF (10-CONT_DECE = 0)
    CALL    	INCREMENTO_DECE_HOR
    
    MOVF	CONT_DECE_HOR, W	    ; W = CONT_DECE
    SUBLW	2			    ; 10 - CONT_DECE
    BTFSC	STATUS, 2		    ; IF (10-CONT_DECE = 0)
    CALL    	REINICIO
    
    ;TRADUCCIÓN A DISPLAY DE 7 SEGMENTOS
    MOVWF	CONT_UNI_MIN, W
    CALL	TABLA
    MOVWF	UNI_MIN
    
    MOVWF	CONT_DECE_MIN, W
    CALL	TABLA
    MOVWF	DECE_MIN
    
    MOVWF	CONT_UNI_HOR, W
    CALL	TABLA
    MOVWF	UNI_HOR
    
    MOVWF	CONT_DECE_HOR, W
    CALL	TABLA
    MOVWF	DECE_HOR
    
    RETURN
    
 RESET_PORT:
    CLRF	CONT_UNI
    CLRF	CONT_UNI_MIN
    CLRF	CONT_DECE_MIN
    CLRF	CONT_UNI_HOR
    CLRF	CONT_DECE_HOR
    RETURN
    
 INCREMENTO_UNI_MIN:
    INCF	CONT_UNI_MIN
    CLRF	CONT_UNI
    RETURN
    
 INCREMENTO_DECE_MIN:
    INCF	CONT_DECE_MIN
    CLRF	CONT_UNI_MIN
    RETURN  
    
 INCREMENTO_UNI_HOR:
    INCF	CONT_UNI_HOR
    CLRF	CONT_DECE_MIN
    RETURN 
    
 INCREMENTO_DECE_HOR:
    INCF	CONT_DECE_HOR
    CLRF	CONT_UNI_HOR
    RETURN
    
 REINICIO:
    MOVF	CONT_UNI_HOR, W		    ; W = CONT_DECE
    SUBLW	4			    ; 10 - CONT_DECE
    BTFSC	STATUS, 2		    ; IF (10-CONT_DECE = 0)
    CALL    	RESET_PORT
    RETURN
 
 
 INT_TMR0:
    REINICIAR_TMR0	
    
    ; SE SELECCIONA EL DISPLAY AL QUE SE DESEA ESCRIBIR
    MOVF	DISP_SELECTOR, W
    MOVWF	PORTD
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE UNIDADES (0001)
    MOVF	DISP_SELECTOR, W
    SUBLW	1			;Chequear si DISP_SELECTOR = 0001
    BTFSC	STATUS, 2
    CALL	DISPLAY_UNI		
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE DECENAS (0010)
    MOVF	DISP_SELECTOR, W
    SUBLW	2			;Chequear si DISP_SELECTOR = 0010
    BTFSC	STATUS, 2
    CALL	DISPLAY_DECE		
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE CENTENAS (0100)
    MOVF	DISP_SELECTOR, W
    SUBLW	4			;Chequear si DISP_SELECTOR = 0100
    BTFSC	STATUS, 2
    CALL	DISPLAY_CEN
    
    ;REVISAR SI SE ESCRIBE EN EL DISPLAY DE CENTENAS (1000)
    MOVF	DISP_SELECTOR, W
    SUBLW	8			;Chequear si DISP_SELECTOR = 1000
    BTFSC	STATUS, 2
    CALL	DISPLAY_MIL
    
    ;MOVER EL 1 EN DISP_SELECTOR 1 POSICIÓN A LA IZQUIERDA
    BCF		STATUS, 0		;Se limpia el bit de carry
    RLF		DISP_SELECTOR, 1	;1 en DISP_SELECTOR se corre una posición a al izquierda
    
    ;REINICIAR DISP_SELECTOR SI EL VALOR SUPERÓ EL NÚMERO DE DISPLAYS
    MOVF	DISP_SELECTOR, W
    SUBLW	16
    BTFSC	STATUS, 2
    CALL	RESET_DISP_SELECTOR
    
    RETURN
    
 DISPLAY_UNI:
    MOVF	UNO, W			;W = UN0
    MOVWF	PORTA			;PORTC = W
    RETURN
    
 DISPLAY_DECE:
    MOVF	DIEZ, W			;W = DIEZ
    MOVWF	PORTA			;PORTC = W
    RETURN
    
 DISPLAY_CEN:
    MOVF	CIEN, W			;W = CIEN
    MOVWF	PORTA			;PORTC = W
    RETURN
    
 DISPLAY_MIL:
    MOVF	MIL, W			;W = MIL
    MOVWF	PORTA			;PORTC = W
    RETURN

 RESET_DISP_SELECTOR:
    CLRF	DISP_SELECTOR
    INCF	DISP_SELECTOR, 1
    RETURN
    
  
 ;------------Posición del código---------------------
 PSECT CODE, DELTA=2, ABS
 ORG 100H		;Posición para el codigo
 
 ;-------------Tabla números--------------------------
 
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
    
 ;-----------Configuración----------------
 MAIN:
    BSF		STATUS_MODO, 0		    ;CONFIGURAR EL STATUS MODO EN 1
    CALL	RESET_DISP_SELECTOR	    ;REINICIAR EL DISPLAYS_SELECTOR
    CALL	CONFIG_IO
    CALL	CONFIG_RELOJ		    ;Configuración del oscilador
    CALL	CONFIG_TMR0		    ;Configuración del Timer 0
    CALL	CONFIG_INT_ENABLE	    ;Configuración de interrupciones
    CALL	CONFIG_TMR2
    BANKSEL	PORTA
    BANKSEL	PORTD
    
 ;---------Loop principal----------------
 LOOP:
    BTFSC	PORTB, 0
    CALL	ANTIREBOTE
    GOTO	LOOP
 
 ;---------------SUBRUTINAS------------------ 
 ;-----------------------------------------
 ;	 LÓGICA DE CONTADORES DE HORA
 ;----------------------------------------- 
 
 
 ;-----------------------------------------
 ;	       STATUS DE MODO
 ;----------------------------------------- 
 ANTIREBOTE:
    BTFSC	PORTB, 0
    GOTO	$-1
    CALL	FLIP_FLOP_GENERAL
    RETURN
 
 FLIP_FLOP_GENERAL:
    MOVF	STATUS_MODO, W
    MOVWF	OLD_STATUS_MODO
    
    BTFSC	OLD_STATUS_MODO, 0
    CALL	HORA_DISPLAYS
    
    BTFSS	OLD_STATUS_MODO, 0
    CALL	FECHA_DISPLAYS
    
    RETURN
       
 HORA_DISPLAYS:
    BCF		STATUS_MODO, 0
    
    MOVF	UNI_MIN, W
    MOVWF	UNO
    
    MOVF	DECE_MIN, W
    MOVWF	DIEZ
    
    MOVF	UNI_HOR, W
    MOVWF	CIEN
    
    MOVF	DECE_HOR, W
    MOVWF	MIL
    
    RETURN
    
 FECHA_DISPLAYS:
    BSF		STATUS_MODO, 0
    MOVLW	01110111B
    MOVWF	UNO
    
    MOVLW	00111001B
    MOVWF	DIEZ
    
    MOVLW	01111001B
    MOVWF	CIEN
    
    MOVLW	01011110B
    MOVWF	MIL
    
    RETURN
 
 ;-----------------------------------------
 ;      CONFIGURACIONES GENERALES
 ;----------------------------------------- 
 CONFIG_TMR2:
    BANKSEL	PORTA
    BSF		TOUTPS3
    BSF		TOUTPS2
    BSF		TOUTPS1
    BSF		TOUTPS0		    ;POSTCALER = 1111 = 1:16
    
    BSF		TMR2ON
    
    BSF		T2CKPS1
    BSF		T2CKPS0		    ;PRESCALER = 16
    
    BANKSEL	TRISB
    MOVLW	122
    MOVWF	PR2
    CLRF	TMR2
    BCF		TMR2IF
    
    RETURN

 
 CONFIG_INT_ENABLE:
    BANKSEL	TRISA
    BSF		TMR2IE		    ;INTERRUPCIÓN TMR2
    
    BANKSEL	PORTA
    BSF		T0IE		    ;HABILITAR TMR0
    BCF		T0IF		    ;BANDERA DE TMR0
  
    BCF		TMR2IF		    ;BANDERA DE TMR2
    
    BSF		PEIE		    ;INTERRUPCIONES PERIFÉRICAS
    BSF		GIE		    ;INTERRUPCIONES GLOBALES
    RETURN

    
 CONFIG_TMR0:
    BANKSEL	TRISA
    BCF		T0CS		    ;Reloj interno
    BCF		PSA		    ;PRESCALER
    BSF		PS2 
    BCF		PS1
    BCF		PS0		    ;Prescaler = 100 = 1:32
    BANKSEL	PORTA
    REINICIAR_TMR0
    RETURN
 
 CONFIG_IO:
    BANKSEL	ANSEL
    CLRF	ANSEL		    ;Pines digitales
    CLRF	ANSELH
    
    BANKSEL	TRISA
    CLRF	TRISA		    ;Port A como salida
    CLRF	TRISD		    ;PORT D COMO SALIDA
    CLRF	TRISC
    
    BSF		TRISB, 0	    ;PORT B COMO ENTRADA
    
    BANKSEL	PORTA
    CLRF	PORTA
    CLRF	PORTD
    CLRF	PORTC
    RETURN
    
 CONFIG_RELOJ:
    BANKSEL	OSCCON
    BCF		IRCF2		    ;IRCF = 001 = 125 KHz
    BCF		IRCF1
    BSF		IRCF0
    BSF		SCS		    ;Reloj interno
    RETURN
    
    
END


