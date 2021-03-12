;-------------------------------------------------------------------------------
; Archivo:	interrupciones.s
; Dispositivo:	PIC16F887
; Autor:	Axel Mazariegos
; Compilador:	pic-as, MPLABX V5.40
;
; Programa: contador en PORTA controlado por interrupciones de cambio del PORTB
;	    contador en PORTD controlado por interrupciones del Timer0
;    
; Hardware: LEDs en PORTA
;	    Botones en PORTB
;	    Display 7 Segmentos en PORTC
;	    Display 7 Segmentos en PORTD
;
; Creado: 28 feb, 2021
; Última modificación: 06 mar, 2021
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

comparar macro	var1, var2
    movf    var1, W
    sublw   var2
    endm
    
    
;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
PSECT udata_shr
W_TEMP:		DS  1
STATUS_TEMP:	DS  1
    
PSECT udata_bank0
display0:   DS 1
display1:   DS 1
display2:   DS 1
display3:   DS 1    
display4:   DS 1 
con7seg:    DS 1
bandera:    DS 1
cont:	    DS 1    
hex0:	    DS 1
hex1:	    DS 1
centena:    DS 1
decena:	    DS 1
unidad:	    DS 1    
numero:	    DS 1
tiempo:	    DS 1
 
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
    goto    $+9
    btfss   PORTB, 0	;si el boton se preciona se va a incrementar 
    incf    PORTA	;si no se preciona el boton se salta una linea
    btfss   PORTB, 0
    goto    $-1
    btfss   PORTB, 1	;si el boton se preciona se va a decrementar
    decf    PORTA	;si no se preciona el boton se salta una linea
    btfss   PORTB, 1
    goto    $-1
    bcf	    RBIF	;apagar la bandera del IOC-PORTB
    
    ;---------------------------------------------------------------------------
    ; Interrupcion Timer0
    ;---------------------------------------------------------------------------
    btfss   T0IF    ;revisar la bandera del tmr0
    ;REINICIAR TIMER0
    goto    pop
    movlw   217	    ;N para obtener 10ms de delay
    movwf   TMR0    ;t_deseado = 4*(1/Fosc)*(256-N)*Prescaler 
    /*
    ;DISPLAYS PUERTO C
    bcf	    PORTB, 6	;apagar transistor del displayC0
    bcf	    PORTB, 7	;apagar transistor del displayC1
    btfsc   bandera, 0	;bandera para cambiar de display
    goto    $+5		;si es 1 se irá al display1
    ;DISPLAY0
    movf    display0, W	;display0 al acumulador
    movwf   PORTC	;mostrar display0
    bsf	    PORTB, 6	;encender el transistor
    goto    $+4
    ;DISPLAY1
    movf    display1, W	;display1 al acumulador
    movwf   PORTC	;mostrar display1
    bsf	    PORTB, 7	;encender el transistor
    ;SIGUIENTE DISPLAY
    movlw   1		;1 al acumulador
    xorwf   bandera, F	;negara el valor de bandera
    */
    bsf	    tiempo, 0
    bcf     T0IF	;apagar la bandera del tmr0
    
          
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
    call config_inicial
    banksel PORTA

    
;-------------------------------------------------------------------------------
; Loop principal
;-------------------------------------------------------------------------------	
loop: 
    
    call numero_hex 
    
    movf    PORTA, W
    movwf   numero
    call    numero_decimal
    
    call preparar_displays
    
    btfsc   tiempo, 0   
    call    displays
    
    goto    loop       

 
;-------------------------------------------------------------------------------
; Subrutinas 
;-------------------------------------------------------------------------------

  
    
displays:
    bcf	    PORTB, 6	;apagar transistor del displayC0
    bcf	    PORTB, 7	;apagar transistor del displayC1
    bcf	    PORTE, 0
    bcf	    PORTE, 1
    bcf	    PORTE, 2	
    
dis0:
    btfss   bandera, 0	;bandera para cambiar de display
    goto    dis1	;si es 1 se irá al display1
    movf    display0, W	;display0 al acumulador
    movwf   PORTC	;mostrar display0
    bsf	    PORTB, 6	;encender el transistor
    goto    siguiente
    
dis1:
    btfss   bandera, 1	;bandera para cambiar de display
    goto    dis2	;si es 1 se irá al display1
    movf    display1, W	;display1 al acumulador
    movwf   PORTC	;mostrar display1
    bsf	    PORTB, 7	;encender el transistor
    goto    siguiente
    
dis2:
    btfss   bandera, 2	;bandera para cambiar de display
    goto    dis3	;si es 1 se irá al display1
    movf    display2, W	;display1 al acumulador
    movwf   PORTD	;mostrar display1
    bsf	    PORTE, 0	;encender el transistor
    goto    siguiente

dis3:
    btfss   bandera, 3	;bandera para cambiar de display
    goto    dis4	;si es 1 se irá al display1
    movf    display3, W	;display1 al acumulador
    movwf   PORTD	;mostrar display1
    bsf	    PORTE, 1	;encender el transistor
    goto    siguiente

dis4:
    btfss   bandera, 4	;bandera para cambiar de display
    goto    siguiente	;si es 1 se irá al display1
    movf    display4, W	;display1 al acumulador
    movwf   PORTD	;mostrar display1
    bsf	    PORTE, 2	;encender el transistor   
     
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
        
    
numero_decimal:  
    
    clrf    centena
    clrf    decena
    clrf    unidad
    
centenas:  ; restar 100 y contar cuantas veces se resto
    movlw   100
    subwf   numero, W
    btfss   STATUS, 0
    goto    decenas
    movwf   numero
    incf    centena
    goto    centenas

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
        
    
numero_hex:
    movf    PORTA, W	;Contador a acumulador
    andlw   0x0F	;Dejar solo los 4 bits menos significativos
    movwf   hex0	
    swapf   PORTA, W	;Invertir los valores del contador 
    andlw   0x0F	;Dejar solo los 4 bits menos significativos
    movwf   hex1	
    return 

preparar_displays:
    movf    hex0, W	;variable0 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display0	
    
    movf    hex1, W	;variable1 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display1
    
    movf    unidad, W	;variable1 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display2
    
    movf    decena, W	;variable1 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display3
    
    movf    centena, W	;variable1 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display4
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
    bsf	    TRISB, 0	;puerto RB0 como entrada
    bsf	    TRISB, 1	;puerto RB1 como entrada
    bcf	    OPTION_REG, 7   ;RBPU=0, habilitar los pull-ups del puerto B    
    bsf	    WPUB, 0	;habilitar pull-up RB0
    bsf	    WPUB, 1	;habilitar pull-up RB1
    clrf    TRISC	;puerto C como salida  
    clrf    TRISD	;puerto D como salida 
    clrf    TRISE	;puerto E como salida 
      
    banksel PORTA
    clrf    PORTA   ;puerto A en 0
    clrf    PORTB   ;puerto B en 0
    clrf    PORTC   ;puerto C en 0
    clrf    PORTD   ;puerto D en 0
    clrf    PORTE   ;puerto D en 0
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
    
    
config_int:
    banksel INTCON
    bsf	    GIE		;GIE=1 habilitar las interrupciones globales
    bsf	    RBIE    	;RBIE=1 habilitar interrupciones de cambio puertoB
    bcf	    RBIF	;apagar la bandera del IOC-PORTB
    bsf	    T0IE	;T0IE=1 habilitar interrupciones Timer0
    bcf	    T0IF	;apagar la bandera del tmr0
    banksel IOCB
    bsf	    IOCB, 0	;habilitar interrupt-on-change RB0
    bsf	    IOCB, 1	;habilitar interrupt-on-change RB1
    return

config_inicial:    
    banksel PORTA
    
    movlw   1
    movwf   bandera
        
    return    
    
    
END


