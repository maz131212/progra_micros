;-------------------------------------------------------------------------------
; Archivo:	interrupciones.s
; Dispositivo:	PIC16F887
; Autor:	Axel Mazariegos
; Compilador:	pic-as, MPLABX V5.40
;
; Programa:     
; Hardware:     
;
; Creado: 23 feb, 2021
; Última modificación: 23 feb, 2021
;-------------------------------------------------------------------------------

    
PROCESSOR 16F887
#include <xc.inc>

;configuration word 1
CONFIG FOSC=INTRC_NOCLKOUT  // Oscilador interno sin salidas
CONFIG WDTE=OFF     // WDT disabled (reinicio repetitivo del pic)
CONFIG PWRTE=ON     // PWRT enable (espera de 72ms al iniciar)
CONFIG MCLRE=OFF    // El pin de MCLR se utiliza como I/O
CONFIG CP=OFF       // Sin portección de código
CONFIG CPD=OFF      // Sin protección de datos 

CONFIG BOREN=OFF    // Sin reinicio cuándo el voltaje de alimentación bajade 4V
CONFIG IESO=OFF     // Reinicio sin cambio de reloj de interno a externo
CONFIG FCMEN=OFF    // Cambio de reloj externo a interno en caso de fallo
CONFIG LVP=ON       // Programación en bajo voltaje permitida

;configuration word 2
CONFIG WRT=OFF      // Protección de autoescritura por el programa desactivada
CONFIG BOR4V=BOR40V // Reinicio abajo de 4V, (BOR21V=2.1V)

  
    
;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------

PSECT udata_shr
 W_TEMP:	DS  1
 STATUS_TEMP:	DS  1
    
PSECT udata_bank0
con7seg:    DS 1
alarma:	    DS 1
cont_small: DS 1    
cont_big:   DS 1   
 
;-------------------------------------------------------------------------------
; Vector Reset
;-------------------------------------------------------------------------------

PSECT resVect, class=CODE, abs, delta=2

ORG 00h     ;posición 0000h para el reset
	
resetVect:
    PAGESEL main    ;seleccionar pagina 
    goto main
	
;-------------------------------------------------------------------------------
; Vector de Interrupcion
;-------------------------------------------------------------------------------

PSECT resVect, class=CODE, abs, delta=2

ORG 04h     ;posición 0004h para las interrupciones
	
push:
    movf    W_TEMP
    swapf   STATUS, W
    movwf   STATUS_TEMP
    
    
isr:
    ;---------------------------------------------------------------------------
    ; IOC puerto B
    ;---------------------------------------------------------------------------
    btfss   RBIF
    goto    pop 
    btfss   PORTB, 0	    ;si el boton se preciona se va a incrementar 
    incf    PORTA	    ;si no se preciona el boton se salta una linea
    btfss   PORTB, 1	    ;si el boton se preciona se va a decrementar
    decf    PORTA	    ;si no se preciona el boton se salta una linea 
    bcf	    RBIF
    
    ;---------------------------------------------------------------------------
    ; Interrupcion Timer0
    ;---------------------------------------------------------------------------
    
    

pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie



    
;-------------------------------------------------------------------------------
; Tablas
;-------------------------------------------------------------------------------

PSECT code, delta=2, abs
 
ORG 100h    ;posición para el código
tabla_7_seg:
    clrf    PCLATH
    bsf     PCLATH, 0   ; posición 01 00h el PC
    andlw   00001111B   ; no saltar más del tamaño de la tabla
    addwf   PCL         ;103h+1h + W = 106h
    
    retlw   00111111B   ;0
    retlw   00000110B   ;1
    retlw   01011011B   ;2
    retlw   01001111B   ;3
    retlw   01100110B   ;4
    retlw   01101101B   ;5
    retlw   01111101B   ;6
    retlw   00000111B   ;7
    retlw   01111111B   ;8
    retlw   01101111B   ;9
    retlw   01110111B   ;A
    retlw   01111100B   ;B
    retlw   00111001B   ;C
    retlw   01011110B   ;D
    retlw   01111001B   ;E
    retlw   01110001B   ;F
    retlw   0
 
;-------------------------------------------------------------------------------
; Configuración
;-------------------------------------------------------------------------------
 
main:
    call config_int	;configuracion interrupciones
    call config_io	;configuracion entradas y salidas
    call config_reloj	;configuracion del oscilador interno
    call config_iocportb
    banksel PORTA

    
;-------------------------------------------------------------------------------
; Loop principal
;-------------------------------------------------------------------------------
	
loop: 
    
     
    
    goto    loop       

 
;-------------------------------------------------------------------------------
; Subrutinas 
;-------------------------------------------------------------------------------

config_io: 
    banksel ANSEL
    clrf    ANSEL   ;pines digitales puerto A 
    clrf    ANSELH  ;pines digitales puerto B

    banksel TRISA  
    clrf    TRISA       ;puerto A como salida 
    bsf	    TRISA, 4	;puerto RA4 como entrada
    bsf	    TRISA, 5	;puerto RA5 como entrada
    bsf	    TRISA, 6	;puerto RA6 como entrada
    bsf	    TRISA, 7	;puerto RA7 como entrada
    
    clrf    TRISB       ;puerto B como salida 
    bsf	    TRISB, 0	;puerto RB0 como entrada
    bsf	    TRISB, 1	;puerto RB1 como entrada
    
    bcf	    OPTION_REG, 7   ;RBPU=0, habilitar los pull-ups del puerto B    
    bsf	    WPUB, 0	;habilitar pull-up RB0
    bsf	    WPUB, 1	;habilitar pull-up RB1
    
    clrf    TRISC   ;puerto C como salida  
    clrf    TRISD   ;puerto D como salida 
      
    banksel PORTA
    clrf    PORTA   ;puerto A en 0
    clrf    PORTB   ;puerto B en 0
    clrf    PORTC   ;puerto C en 0
    clrf    PORTD   ;puerto D en 0
    return

    
config_reloj:
    banksel OSCCON  
    bsf     IRCF2   ;oscilador de 4 MHz (110)
    bsf     IRCF1
    bcf     IRCF0
    bsf     SCS     ;OSCILADOR INTERNO
    return
    
config_int:
    banksel INTCON
    bsf	    INTCON, 7	;GIE=1 habilitar las interrupciones globales
    bsf	    INTCON, 3	;RBIE=1 habilitar interrupciones de cambio puertoB
    bcf	    RBIF
    ;bsf	    INTCON, 2	;T0IF=1 habilitar interrupciones Timer0
    return

config_iocportb:
    banksel IOCB
    bsf	    IOCB, 0	;habilitar interrupt-on-change RB0
    bsf	    IOCB, 1	;habilitar interrupt-on-change RB1
    
    banksel PORTB
    movf    PORTB, W
    bcf	    RBIF
    return
    

    
    
    
END



