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
    call config_io	;configuracion entradas y salidas
    call config_reloj	;configuracion del oscilador interno
    call config_tmr0	;configuracion del timer0
    banksel PORTA

    
;-------------------------------------------------------------------------------
; Loop principal
;-------------------------------------------------------------------------------
	
loop: 
    btfsc   T0IF	;si la bandera es 1 se increenta el contador (puertoB)
    incf    PORTB   
    
    btfsc   T0IF	;si la bandera es 1 se reinicia el tmr0
    call    reiniciar_tmr0
    
    btfsc   PORTA, 0	    ;si el boton se preciona se va a incrementar 
    call    incrementar	    ;si no se preciona el boton se salta una linea
    
    btfsc   PORTA, 1	    ;si el boton se preciona se va a decrementar
    call    decrementar	    ;si no se preciona el boton se salta una linea  
    
    call    igualdad	    ;compara si los contadores son iguales
    
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
    bsf	    TRISA, 0	;puerto RA0 como entrada
    bsf	    TRISA, 1	;puerto RA1 como entrada
    
    clrf    TRISB       ;puerto B como salida 
    bsf	    TRISB, 4	;puerto RB4 como entrada
    bsf	    TRISB, 5	;puerto RB5 como entrada
    bsf	    TRISB, 6	;puerto RB6 como entrada
    bsf	    TRISB, 7	;puerto RB7 como entrada
    
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
    bcf     IRCF2   ;oscilador de 250 kHz (010)
    bsf     IRCF1
    bcf     IRCF0
    bsf     SCS     ;OSCILADOR INTERNO
    return

config_tmr0:
    banksel OPTION_REG
    bcf     T0CS    ;reloj interno 
    bcf     PSA     ;prescaler en tmr0

    bsf     PS2     ;configurar el prescaler (111 = 1:256)
    bsf     PS1
    bsf     PS0

    banksel PORTA   ;bank0
    call reiniciar_tmr0
    return

reiniciar_tmr0:
    movlw   133	    ;N para obtener 0.5seg de delay
    movwf   TMR0    
    bcf     T0IF    ;apagar la bandera del tmr0
    return

    
incrementar:
    btfss   PORTA, 0	;antirrebote
    goto    $-1
    btfsc   PORTA, 0
    goto    $-1
    incf    con7seg	;incrementar el contador
    movf    con7seg, W	;contador a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   PORTC	;mostrar el valor en el 7 segmentos
    return
    
    
decrementar:
    btfss   PORTA, 1	;antirrebote
    goto    $-1
    btfsc   PORTA, 1
    goto    $-1
    decf    con7seg	;decrementar el contador
    movf    con7seg, W	;contador a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   PORTC	;mostrar el valor en el 7 segmentos
    return  
    
    
igualdad:
    movf    PORTB, W	;pueto B a el acumulador
    subwf   con7seg, W	;restar acumulador y 7seg, respuesta en el acumulador
    btfss   STATUS, 2	;--Z-- si Z=0 no es igual, si Z=1 es igual
    goto    noigual
    
    call    delay_big	;espera un poco
    bsf	    PORTD, 0	;encender la alarma
    clrf    PORTB	;reinicar el contador del tmr0 (puerto B) 
    call    delay_big	;delay para ver la alarma 
    call    reiniciar_tmr0  ;reiniciar tmr0
noigual:
    bcf	    PORTD, 0	;apagar la alarma
    return

    
delay_big:
    movlw   200             ;valor inicial del contador
    movwf   cont_big
    call    delay_small     ;rutina de delay
    decfsz  cont_big, 1     ;decrementar el contador
    goto    $-2             ;ejecutar dos lineas atras
    return

delay_small:
    movlw   32		    ;valor inicial del contador
    movwf   cont_small
    decfsz  cont_small, 1   ;decrementar el contador
    goto    $-1             ;ejecutar linea anterior
    return
    
    
END
