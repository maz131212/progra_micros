;-------------------------------------------------------------------------------
; Archivo:	contadores.s
; Dispositivo:	PIC16F887
; Autor:	Axel Mazariegos
; Compilador:	pic-as, MPLABX V5.40
;
; Programa:     contador en el puerto B y C
; Hardware:     LEDs en el puerto B, C y D
;
; Creado: 9 feb, 2021
; Última modificación: 10 feb, 2021
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
; Macros
;-------------------------------------------------------------------------------

bank0 macro
    bcf STATUS, 5
    bcf STATUS, 6
    endm
    
bank1 macro
    bsf STATUS, 5
    bcf STATUS, 6
    endm
    
bank2 macro
    bcf STATUS, 5
    bsf STATUS, 6
    endm
    
bank3 macro
    bsf STATUS, 5
    bsf STATUS, 6
    endm
    
    
;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------

; no se usaron variables en este laboratorio
    
	 
    
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
    bank3
    clrf    ANSEL       ;pines digitales puerto A 
    clrf    ANSELH	;pines digitales puerto B

    bank1
    clrf    TRISA       ;puerto A como salida PRUEBA
    clrf    TRISB       ;puerto B como salida
    clrf    TRISC       ;puerto C como salida
    clrf    TRISD       ;puerto D como salida
    
    bsf	    TRISB, 4	;puerto B4 como entrada (este será un botón)
    bsf	    TRISB, 5	;puerto B5 como entrada (este será un botón)
    bsf	    TRISB, 6	;puerto B6 como entrada 
    bsf	    TRISB, 7	;puerto B7 como entrada
    ;el puerto B6 y B7 están como entrada para no afectar el contador de 4 bits
    
    bsf	    TRISC, 4	;puerto C4 como entrada (este será un botón)
    bsf	    TRISC, 5	;puerto C5 como entrada (este será un botón)
    bsf	    TRISC, 6	;puerto C6 como entrada
    bsf	    TRISC, 7	;puerto C7 como entrada
    ;el puerto C6 y C7 están como entrada para no afectar el contador de 4 bits
    
    bsf	    TRISD, 5	;puerto D5 como entrada (este será un botón)
    bsf	    TRISD, 6	;puerto D6 como entrada
    bsf	    TRISD, 7	;puerto D7 como entrada
    ;el puerto D6 y D7 están como entrada para no afectar el contador de 4 bits
    
    bank0

    clrf    PORTA       ;puerto A como salida PRUEBA
    clrf    PORTB       ;puerto B como salida
    clrf    PORTC       ;puerto C como salida
    clrf    PORTD       ;puerto D como salida
    
    
    
;-------------------------------------------------------------------------------
; Loop principal
;-------------------------------------------------------------------------------
	
loop:
    
    btfsc   PORTB, 4	    ;si el botón se preciona se va a incrementar 1
    call    incrementar1    ;si no se preciona el botón se salta una linea
    
    btfsc   PORTB, 5
    call    decrementar1
    
    btfsc   PORTC, 4
    call    incrementar2
    
    btfsc   PORTC, 5
    call    decrementar2
    
    btfsc   PORTD, 5 
    call    sumar
    
    
    goto    loop       


    
;-------------------------------------------------------------------------------
; Subrutinas 
;-------------------------------------------------------------------------------
    
incrementar1:
    btfss   PORTB, 4
    goto    $-1
    btfsc   PORTB, 4
    goto    $-1
    incf    PORTB
    return
    
decrementar1:
    btfss   PORTB, 5
    goto    $-1
    btfsc   PORTB, 5
    goto    $-1
    decf    PORTB
    return

incrementar2:
    btfss   PORTC, 4
    goto    $-1
    btfsc   PORTC, 4
    goto    $-1
    incf    PORTC
    return
    
decrementar2:
    btfss   PORTC, 5
    goto    $-1
    btfsc   PORTC, 5
    goto    $-1
    decf    PORTC
    return

sumar:
    btfss   PORTD, 5
    goto    $-1
    btfsc   PORTD, 5
    goto    $-1
    
    movf    PORTC, W	;portc a w
    addwf   PORTB, W	;sumar portB y portC dejarlo en W
    movwf   PORTD	; w a portD
    
    return
    
    
END
;-------------------------------------------------------------------------------
; FIN 
;-------------------------------------------------------------------------------