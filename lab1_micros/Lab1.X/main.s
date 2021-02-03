; Archivo:	main.s
; Dispositivo:	PIC16F887
; Autor:	Axel Mazariegos
; Compilador:	pic-as, MPLABX V5.40
;
; Programa:     contador en el puerto A
; Hardware:     LEDs en el puerto A
;
; Creado: 2 feb, 2021
; �ltima modificaci�n: 2 feb, 2021
    
PROCESSOR 16F887
#include <xc.inc>

;configuration word 1
CONFIG FOSC=INTRC_NOCLKOUT  // Oscilador Interno sin salidas
CONFIG WDTE=OFF     // WDT disabled (reinicio repetitivo del pic)
CONFIG PWRTE=ON     // PWRT enable (espera de 72ms al iniciar)
CONFIG MCLRE=OFF    // El pin de MCLR se utiliza como I/O
CONFIG CP=OFF       // Sin portecci�n de c�digo
CONFIG CPD=OFF      // Sin protecci�n de datos 

CONFIG BOREN=OFF    // Sin reinicio cu�ndo el voltaje de alimentaci�n bajade 4V
CONFIG IESO=OFF     // Reinicio sin cambio de reloj de interno a externo
CONFIG FCMEN=OFF    // Cambio de reloj externo a interno en caso de fallo
CONFIG LVP=ON       // Programaci�n en bajo voltaje permitida

;configuration word 2
CONFIG WRT=OFF      // Protecci�n de autoescritura por el programa desactivada
CONFIG BOR4V=BOR40V // Reinicio abajo de 4V, (BOR21V=2.1V)


PSECT udata_bank0   ;common memory
    cont_small: DS 1    ;1 byte
    cont_big:   DS 1


PSECT resVect, class=CODE, abs, delta=2
;--------------vector reset---------------
ORG 00h     ;posici�n 0000h para el reset
resetVec:
    PAGESEL main
    goto main


PSECT code, delta=2, abs
ORG 100h    ;posici�n para el c�digo
;--------------configuraci�n---------------
main:
    bsf	    STATUS, 5   ;banco 11
    bsf     STATUS, 6
    clrf    ANSEL       ;pines digitales 
    clrf    ANSELH

    bsf     STATUS, 5   ;banco 01
    bcf     STATUS, 6
    clrf    TRISA       ;port A como salida

    bcf     STATUS, 5   ;banco 01
    bcf     STATUS, 6


;--------------loop principal---------------
loop:
    incf    PORTA,  1   
    call    delay_big
    goto    loop       ;loop forever


;--------------sub rutinas---------------
delay_big:
    movlw   200              ;valor inicial del contador
    movwf   cont_big
    call    delay_small     ;rutina de delay
    decfsz  cont_big, 1     ;decrementar el contador
    goto    $-2             ;ejecutar dos l�neas atr�s
    return

delay_small:
    movlw   249             ;valor inicial del contador
    movwf   cont_small
    decfsz  cont_small, 1   ;decrementar el contador
    goto    $-1             ;ejecutar l�nea anterior
    return

END

    


