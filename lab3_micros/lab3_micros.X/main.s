;-------------------------------------------------------------------------------
; Archivo:	timer0.s
; Dispositivo:	PIC16F887
; Autor:	Axel Mazariegos
; Compilador:	pic-as, MPLABX V5.40
;
; Programa:     
; Hardware:     
;
; Creado: 15 feb, 2021
; Última modificación: 15 feb, 2021
;-------------------------------------------------------------------------------

    
PROCESSOR 16F887
#include <xc.inc>

;configuration word 1
CONFIG FOSC=XT	    // Oscilador Externo
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

PSECT udata_bank0
var:    DS 1, 1byte
 
;-------------------------------------------------------------------------------
; Vector Reset
;-------------------------------------------------------------------------------

PSECT resVect, class=CODE, abs, delta=2

ORG 00h     ;posición 0000h para el reset
	
resetVect:
    PAGESEL main    ;seleccionar pagina 
    goto main
	
    
    
;-------------------------------------------------------------------------------
; Configuración
;-------------------------------------------------------------------------------

PSECT code, delta=2, abs
 
ORG 100h    ;posición para el código

main:
    call config_io
    call config_reloj
    call config_tmr0

    
    
;-------------------------------------------------------------------------------
; Loop principal
;-------------------------------------------------------------------------------
	
loop:
    
    btfss   T0IF    ;bandera de interrupcion para el timer0
    goto    $-1
    call    reiniciar_tmr0
    incf    PORTA
    goto    loop       


    
;-------------------------------------------------------------------------------
; Subrutinas 
;-------------------------------------------------------------------------------


config_io:
    
    banksel ANSEL
    clrf    ANSEL       ;pines digitales puerto A 
    clrf    ANSELH	;pines digitales puerto B

    banksel TRISA  
    clrf    TRISA       ;puerto A como salida 
    bsf	    TRISA, 0	;puerto RA0 como entrada
    bsf	    TRISA, 1	;puerto RA1 como entrada
    
    clrf    TRISB       ;puerto B como salida 
    bsf	    TRISB, 4	;puerto RB4 como entrada
    bsf	    TRISB, 5	;puerto RB5 como entrada
    bsf	    TRISB, 6	;puerto RB6 como entrada
    bsf	    TRISB, 7	;puerto RB7 como entrada
    
    clrf    TRISC	;puerto C como salida 
    
    clrf    TRISD	;puerto D como salida 
    
    
    banksel PORTA
    clrf    PORTA       ;puerto A en 0
    clrf    PORTB       ;puerto B en 0
    clrf    PORTC       ;puerto C en 0
    clrf    PORTD       ;puerto D en 0

    return

config_reloj:
    banksel OSCCON  

    ;bcf     OSCCON, 6   ;oscilador de 500kHz
    ;bsf     OSCCON, 5
    ;bsf     OSCCON, 4

    bcf     IRCF2   ;oscilador de 500kHz
    bsf     IRCF1
    bsf     IRFC0
    bsf     SCS     ;OSCILADOR INTERNO

    return

config_tmr0:
    banksel OPTION_REG

    bcf     T0CS    ;reloj interno 
    bcf     PSA     ;prescaler en tmr0

    bsf     PS2     ;configurar el prescaler
    bsf     PS1
    bcf     PS0

    banksel PORTA   ;bank0
    call reiniciar_tmr0
    return

reiniciar_tmr0:
    movlw   50
    movwf   TMR0
    bcf     TOIF
    return

END
;-------------------------------------------------------------------------------
; FIN 
;-------------------------------------------------------------------------------
