;-------------------------------------------------------------------------------
; Archivo:	proyecto1.s
; Dispositivo:	PIC16F887
; Autor:	Axel Mazariegos
; Compilador:	pic-as, MPLABX V5.40
;
; Programa: 
;    
; Hardware: 
;
; Creado: 09 mar, 2021
; Última modificación: 
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
; Macros
;-------------------------------------------------------------------------------
    
;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
PSECT udata_shr
W_TEMP:		DS  1
STATUS_TEMP:	DS  1
    
PSECT udata_bank0
uni0:	DS 1
uni1:	DS 1    
uni2:	DS 1
uni3:	DS 1    
dec0:	DS 1    
dec1:	DS 1    
dec2:	DS 1    
dec3:	DS 1
    
display0:   DS 1
display1:   DS 1
display2:   DS 1
display3:   DS 1
display4:   DS 1
display5:   DS 1
display6:   DS 1
display7:   DS 1
 
decena:	    DS 1
unidad:	    DS 1
    
modo:	    DS 1
prueba:	    DS 1
numero:	    DS 1
bandera:    DS 1
tiempo:	    DS 1
tiempo1:    DS 1    
tiempo2:    DS 1    
    
    
via1:	    DS 1
via2:	    DS 1
via3:	    DS 1
    
tv1:	    DS 1
tv2:	    DS 1
tv3:	    DS 1
ttv:	    DS 1
ta:	    DS 1
tr1:	    DS 1
tr2:	    DS 1
tr3:	    DS 1

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
PSECT intVect, class=CODE, abs, delta=2

ORG 04h     ;posición 0004h para las interrupciones
	
push:
    movf    W_TEMP	;guardar W en una variable temporal
    swapf   STATUS, W	;inveritr los valores de STATUS
    movwf   STATUS_TEMP	;guardar STATUS en una variable temporal
     
isr:
    ;---------------------------------------------------------------------------
    ; IOC puerto B
    ;---------------------------------------------------------------------------
    btfss   RBIF	;revisar la bandera del IOC-PORTB
    goto    salirB
    btfss   PORTB, 3	;si el boton se preciona se va a incrementar 
    incf    modo	;si no se preciona el boton se salta una linea
    btfss   PORTB, 3
    goto    $-1
    btfss   PORTB, 4	;si el boton se preciona se va a incrementar 
    incf    prueba	;si no se preciona el boton se salta una linea
    btfss   PORTB, 4
    goto    $-1
    btfss   PORTB, 5	;si el boton se preciona se va a decrementar
    decf    prueba	;si no se preciona el boton se salta una linea
    btfss   PORTB, 5
    goto    $-1
    salirB:
    bcf	    RBIF	;apagar la bandera del IOC-PORTB
    
    ;---------------------------------------------------------------------------
    ; Interrupcion Timer0
    ;---------------------------------------------------------------------------
    btfss   T0IF    ;revisar la bandera del tmr0
    ;REINICIAR TIMER0
    goto    itimer1
    movlw   217	    ;N para obtener 10ms de delay
    movwf   TMR0    ;t_deseado = 4*(1/Fosc)*(256-N)*Prescaler 

    bsf	    tiempo, 0
    
    bcf     T0IF	;apagar la bandera del tmr0
    
    ;---------------------------------------------------------------------------
    ; Interrupcion Timer1
    ;---------------------------------------------------------------------------
    itimer1:
    btfss   TMR1IF
    goto    itimer2 
    movlw   0x0B
    movwf   TMR1L    
    movlw   0x47
    movwf   TMR1H   
    
    incf    tiempo1
    btfss   tiempo1, 2
    goto    $+3
    
    incf    prueba
    clrf    tiempo1
    
    bcf	    TMR1IF
    
    ;---------------------------------------------------------------------------
    ; Interrupcion Timer2
    ;---------------------------------------------------------------------------
    itimer2:
    btfss   TMR2IF 
    goto    pop
    
    incf    tiempo2
    
    bcf	    TMR2IF
          
pop:
    swapf   STATUS_TEMP, W  ;inveritr los valores de STATUS
    movwf   STATUS	    ;regresar STATUS 
    swapf   W_TEMP, F	    ;inveritr los valores de W
    swapf   W_TEMP, W	    ;inveritr los valores de W y regresarlo
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
    addwf   PCL         ; 103h+1h + W 
    
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
    call config_int	;configuracion interrupciones
    call config_reloj	;configuracion del oscilador interno	
    call config_tmr0	;configuracion del timer0
    call config_tmr1	;configuracion del timer1
    call config_tmr2	;configuracion del timer2
    call config_inicial
    
    
    banksel PORTA

    
;-------------------------------------------------------------------------------
; Loop principal
;-------------------------------------------------------------------------------	
loop: 
    
    
    
    call mostrar_modo
    
    
    movf    prueba, W
    movwf   numero
    call numero_decimal
    
    movf    decena, W
    movwf   dec0
    
    movf    unidad, W
    movwf   uni0
    
    
    call preparar_displays
    
    btfsc   tiempo, 0   
    call    displays
    
    
    
    goto    loop       

 
;-------------------------------------------------------------------------------
; Subrutinas 
;-------------------------------------------------------------------------------

    
numero_decimal:  
    clrf    decena
    clrf    unidad

decenas:  ; restar 10 y contar cuantas veces se resto
    movlw   10
    subwf   numero, W
    btfss   STATUS, 0
    goto    unidades
    movwf   numero
    incf    decena
    goto    decenas
    
unidades:  ; lo que queda son las unidades
    movf    numero, W
    movwf   unidad
    
    return

    
preparar_displays:
    movf    uni0, W	;variable0 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display0	
    
    movf    dec0, W	;variable1 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display1
    
    movf    uni1, W	;variable1 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display2
    
    movf    dec1, W	;variable1 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display3
    
    movf    uni2, W	;variable1 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display4
    
    movf    dec2, W	;variable1 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display5
    
    movf    uni3, W	;variable1 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display6
    
    movf    dec3, W	;variable1 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display7
    
    return    
    
    
displays:
    ;DISPLAYS PUERTO C
    clrf    PORTA	;apagar transistor del displayC
      
dis0:
    btfss   bandera, 0	;bandera para cambiar de display
    goto    dis1	;si es 1 se irá al display1
    movf    display0, W	;display0 al acumulador
    movwf   PORTC	;mostrar display0
    bsf	    PORTA, 0	;encender el transistor
    goto    siguiente
    
dis1:
    btfss   bandera, 1	;bandera para cambiar de display
    goto    dis2	;si es 1 se irá al display1
    movf    display1, W	;display1 al acumulador
    movwf   PORTC	;mostrar display1
    bsf	    PORTA, 1	;encender el transistor
    goto    siguiente
    
dis2:
    btfss   bandera, 2	;bandera para cambiar de display
    goto    dis3	;si es 1 se irá al display1
    movf    display2, W	;display1 al acumulador
    movwf   PORTC	;mostrar display1
    bsf	    PORTA, 2	;encender el transistor
    goto    siguiente

dis3:
    btfss   bandera, 3	;bandera para cambiar de display
    goto    dis4	;si es 1 se irá al display1
    movf    display3, W	;display1 al acumulador
    movwf   PORTC	;mostrar display1
    bsf	    PORTA, 3	;encender el transistor
    goto    siguiente

dis4:
    btfss   bandera, 4	;bandera para cambiar de display
    goto    dis5	;si es 1 se irá al display1
    movf    display4, W	;display0 al acumulador
    movwf   PORTC	;mostrar display0
    bsf	    PORTA, 4	;encender el transistor
    goto    siguiente
    
dis5:
    btfss   bandera, 5	;bandera para cambiar de display
    goto    dis6	;si es 1 se irá al display1
    movf    display5, W	;display1 al acumulador
    movwf   PORTC	;mostrar display1
    bsf	    PORTA, 5	;encender el transistor
    goto    siguiente
    
dis6:
    btfss   bandera, 6	;bandera para cambiar de display
    goto    dis7	;si es 1 se irá al display1
    movf    display6, W	;display1 al acumulador
    movwf   PORTC	;mostrar display1
    bsf	    PORTA, 6	;encender el transistor
    goto    siguiente

dis7:
    btfss   bandera, 7	;bandera para cambiar de display
    goto    siguiente	;si es 1 se irá al display1
    movf    display7, W	;display1 al acumulador
    movwf   PORTC	;mostrar display1
    bsf	    PORTA, 7	;encender el transistor   
     
siguiente:
    rlf	    bandera, F	;negara el valor de bandera
    
    btfsc   CARRY
    goto    reiniciar 
    goto    exit

reiniciar:
    movlw   1
    movwf   bandera
    
exit:
    bcf	    tiempo, 0
    
    return
    
    
    
mostrar_modo:

m1:
    movlw   1		;pueto B a el acumulador
    subwf   modo, W	;restar acumulador y 7seg, respuesta en el acumulador
    btfss   STATUS, 2	;--Z-- si Z=0 no es igual, si Z=1 es igual
    goto    m2
    bsf	    PORTE, 0
    bcf	    PORTE, 1 
    bcf	    PORTE, 2 
    bcf	    PORTD, 3
    bcf	    PORTD, 4
    goto    salirmodo
m2:
    movlw   2		;pueto B a el acumulador
    subwf   modo, W	;restar acumulador y 7seg, respuesta en el acumulador
    btfss   STATUS, 2	;--Z-- si Z=0 no es igual, si Z=1 es igual
    goto    m3
    bsf	    PORTE, 1
    bcf	    PORTE, 0 
    bcf	    PORTE, 2 
    bcf	    PORTD, 3
    bcf	    PORTD, 4
    goto    salirmodo
m3:
    movlw   3		;pueto B a el acumulador
    subwf   modo, W	;restar acumulador y 7seg, respuesta en el acumulador
    btfss   STATUS, 2	;--Z-- si Z=0 no es igual, si Z=1 es igual
    goto    m4
    bsf	    PORTE, 2
    bcf	    PORTE, 0 
    bcf	    PORTE, 1 
    bcf	    PORTD, 3
    bcf	    PORTD, 4
    goto    salirmodo
m4:
    movlw   4		;pueto B a el acumulador
    subwf   modo, W	;restar acumulador y 7seg, respuesta en el acumulador
    btfss   STATUS, 2	;--Z-- si Z=0 no es igual, si Z=1 es igual
    goto    m5
    bsf	    PORTD, 3
    bcf	    PORTE, 0 
    bcf	    PORTE, 1 
    bcf	    PORTE, 2 
    bcf	    PORTD, 4
    goto    salirmodo
m5:
    movlw   5		;pueto B a el acumulador
    subwf   modo, W	;restar acumulador y 7seg, respuesta en el acumulador
    btfss   STATUS, 2	;--Z-- si Z=0 no es igual, si Z=1 es igual
    goto    m6
    bsf	    PORTD, 4
    bcf	    PORTE, 0 
    bcf	    PORTE, 1 
    bcf	    PORTE, 2 
    bcf	    PORTD, 3
    goto    salirmodo
m6:
    movlw   6		;pueto B a el acumulador
    subwf   modo, W	;restar acumulador y 7seg, respuesta en el acumulador
    btfss   STATUS, 2	;--Z-- si Z=0 no es igual, si Z=1 es igual
    goto    salirmodo
    movlw   1
    movwf   modo
    goto    m1
    
salirmodo:    
    return

;-------------------------------------------------------------------------------
; Subrutinas de configuración
;-------------------------------------------------------------------------------
    
config_io: 
    banksel ANSEL
    clrf    ANSEL   ;pines digitales puerto A 
    clrf    ANSELH  ;pines digitales puerto B

    banksel TRISA  
    clrf    TRISA       ;puerto A como salida 
    clrf    TRISB       ;puerto B como salida 
    bsf	    TRISB, 3	;puerto RB0 como entrada
    bsf	    TRISB, 4	;puerto RB1 como entrada
    bsf	    TRISB, 5	;puerto RB2 como entrada
    bsf	    TRISB, 6	;puerto RB6 como entrada
    bsf	    TRISB, 7	;puerto RB7 como entrada
    bcf	    OPTION_REG, 7   ;RBPU=0, habilitar los pull-ups del puerto B    
    bsf	    WPUB, 3	;habilitar pull-up RB0
    bsf	    WPUB, 4	;habilitar pull-up RB1
    bsf	    WPUB, 5	;habilitar pull-up RB2
    clrf    TRISC	;puerto C como salida  
    clrf    TRISD	;puerto D como salida 
    clrf    TRISE	;puerto E como salida 
      
    banksel PORTA
    clrf    PORTA   ;puerto A en 0
    clrf    PORTB   ;puerto B en 0
    clrf    PORTC   ;puerto C en 0
    clrf    PORTD   ;puerto D en 0
    clrf    PORTE   ;puerto E en 0
    return

    
config_reloj:
    banksel OSCCON  
    bsf     IRCF2   ;oscilador de 4 MHz (110)
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
    call reiniciar_tmr0
    return

reiniciar_tmr0:
    banksel PORTA   ;bank0
    movlw   217	    ;N para obtener 10ms de delay
    movwf   TMR0    ;t_deseado = 4*(1/Fosc)*(256-N)*Prescaler
    bcf     T0IF    ;apagar la bandera del tmr0
    return
    

config_tmr1:
    banksel T1CON
    
    bsf	    TMR1ON  ;habilitar Timer1
    bcf	    TMR1GE  ;Timer1 siempre contando
    bcf	    T1OSCEN ;oscilador apagado
    bcf     TMR1CS  ;reloj interno 
    
    bsf     T1CKPS1 ;configurar el prescaler (11 = 1:8)
    bsf     T1CKPS0
    
    call reiniciar_tmr1
    return

reiniciar_tmr1:
    banksel PIR1    ;bank0 - en este banco tambien está TMR1L y TMR1H
    ; tiempo = (65536 - N) * prescaler * (1/Fosc/4)
    ; N = 2,887 = 0x0B47 para un delay de 1/2 segundo
    movlw   0x0B
    movwf   TMR1L    
    movlw   0x47
    movwf   TMR1H    
    bcf	    TMR1IF
    return
    
config_tmr2:
    banksel T2CON
    
    bsf	    TMR2ON  ;habilitar Timer2
    
    bsf     T2CKPS1 ;configurar el prescaler (11 = 1:16)
    bsf	    T2CKPS0
    
    bsf     TOUTPS3 ;configurar el postscaler (1111 = 1:16)
    bsf     TOUTPS2
    bsf     TOUTPS1
    bsf     TOUTPS0
    
    ;para un tiempo de 0.0625 segundos
    banksel PR2
    movlw   244
    movwf   PR2  
    
    bcf	    TMR2IF
    return

    
config_int:
    banksel INTCON
    bsf	    GIE		;GIE=1 habilitar las interrupciones globales
    bsf	    RBIE    	;RBIE=1 habilitar interrupciones de cambio puertoB
    bcf	    RBIF	;apagar la bandera del IOC-PORTB
    bsf	    T0IE	;T0IE=1 habilitar interrupciones Timer0
    bcf	    T0IF	;apagar la bandera del tmr0
    bsf	    PEIE	;habilitar las interrupciones perifericas
    
    banksel IOCB
    bsf	    IOCB, 3	;habilitar interrupt-on-change RB3
    bsf	    IOCB, 4	;habilitar interrupt-on-change RB4
    bsf	    IOCB, 5	;habilitar interrupt-on-change RB5
    
    banksel PIE1
    bsf	    TMR2IE	;habilitar interrupciones Timer2
    bsf	    TMR1IE	;habilitar interrupciones Timer1
    ;banksel PIR1
    ;bcf	    TMR2IF
    ;bcf	    TMR1IF
    
    return

config_inicial:    
    banksel PORTA
    
    movlw   1
    movwf   bandera
    
    movlw   3
    movwf   ttv
    
    movlw   3
    movwf   ta
    
    movlw   1
    movwf   modo
        
    return
    
    
END





