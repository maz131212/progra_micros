;-------------------------------------------------------------------------------
; Archivo:	lab6_micros.s
; Dispositivo:	PIC16F887
; Autor:	Axel Mazariegos
; Compilador:	pic-as, MPLABX V5.40
;
; Programa: 
;    
; Hardware: 
;
; Creado: 23 mar, 2021
; Última modificación: 28 mar, 2021
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
prueba:	DS 1
numero: DS 1
decena:	DS 1
unidad:	DS 1    
dec0:	DS 1
uni0:	DS 1
tiempo:	DS 1   

bandera:    DS 1    
display0:   DS 1	    
display1:   DS 1   

flag:	DS 1
   

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
    ; Interrupcion Timer1
    ;---------------------------------------------------------------------------
    btfss   TMR1IF
    goto    itimer2 
    movlw   0xBD
    movwf   TMR1L    
    movlw   0xF0
    movwf   TMR1H
    
    incf    prueba
    incf    PORTA
    
    bcf	    TMR1IF
    
    ;---------------------------------------------------------------------------
    ; Interrupcion Timer2
    ;---------------------------------------------------------------------------
    itimer2:
    btfss   TMR2IF 
    goto    itimer0
    
    incf    PORTB
    bsf	    tiempo, 2
    
    bcf	    TMR2IF
    ;---------------------------------------------------------------------------
    ; Interrupcion Timer0
    ;---------------------------------------------------------------------------
    itimer0:
    btfss   T0IF    ;revisar la bandera del tmr0
    ;REINICIAR TIMER0
    goto    pop
    movlw   241	    ;N para obtener 2ms de delay
    movwf   TMR0    ;t_deseado = 4*(1/Fosc)*(256-N)*Prescaler 

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
    call config_tmr1	;configuracion del timer0
    call config_tmr2
    
    banksel PORTA

;-------------------------------------------------------------------------------
; Loop principal
;-------------------------------------------------------------------------------	
loop: 
    
    movf    prueba, W
    movwf   numero
    call numero_decimal
    
    call preparar_displays
    
    btfsc   tiempo, 2
    call    parpadeo
    
    btfsc   flag, 0
    goto    loop
    
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
    movf    unidad, W	;variable0 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display0	
    
    movf    decena, W	;variable1 a acumulador
    call    tabla_7_seg	;obtner el valor correcto en el acumulador
    movwf   display1
    
    return    
    
    
displays:
    ;DISPLAYS PUERTO C
    clrf    PORTD	;apagar transistor del displayC
      
dis0:
    btfss   bandera, 0	;bandera para cambiar de display
    goto    dis1	;si es 1 se irá al display1
    movf    display0, W	;display0 al acumulador
    movwf   PORTC	;mostrar display0
    bsf	    PORTD, 0	;encender el transistor
    goto    siguiente
    
dis1:
    movf    display1, W	;display1 al acumulador
    movwf   PORTC	;mostrar display1
    bsf	    PORTD, 1	;encender el transistor
   
siguiente:
    movlw   1		;1 al acumulador
    xorwf   bandera, F	;negara el valor de bandera
   
    bcf	    tiempo, 0
    
    return
    
parpadeo:
    
    movlw   1		;1 al acumulador
    xorwf   flag, F	;negara el valor de flag
    
    movf    flag, W
    movwf   PORTE
    
    clrf    PORTD
    bcf	    tiempo, 2
    
    return
    
;-------------------------------------------------------------------------------
; Subrutinas de configuración
;-------------------------------------------------------------------------------
    
config_io: 
    
    banksel ANSEL
    clrf    ANSEL
    clrf    ANSELH

    banksel TRISA  
    clrf    TRISA	;puerto A como salida 
    clrf    TRISB	;puerto B como salida 
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
    bcf     IRCF2   ;oscilador de 125 KHz (001)
    bcf     IRCF1
    bsf     IRCF0
    bsf     SCS     ;OSCILADOR INTERNO
    return

        
config_tmr0:
    banksel OPTION_REG
    bcf     T0CS    ;reloj interno 
    bcf     PSA     ;prescaler en tmr0
    bcf     PS2     ;configurar el prescaler (000 = 1:2)
    bcf     PS1
    bcf     PS0
    call reiniciar_tmr0
    return

reiniciar_tmr0:
    banksel PORTA   ;bank0
    movlw   241	    ;N para obtener 2ms de delay
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
    ; N = 61,629 = 0xF0BD para un delay de 1 segundo
    movlw   0xBD
    movwf   TMR1L    
    movlw   0xF0
    movwf   TMR1H    
    bcf	    TMR1IF
    return
    
config_tmr2:
    banksel T2CON
    
    bsf	    TMR2ON  ;habilitar Timer2
    
    bcf     T2CKPS1 ;configurar el prescaler (01 = 1:4)
    bsf	    T2CKPS0
    
    bsf     TOUTPS3 ;configurar el postscaler (1111 = 1:16)
    bsf     TOUTPS2
    bsf     TOUTPS1
    bsf     TOUTPS0
    
    banksel PR2
    movlw   122
    movwf   PR2  
    
    call reiniciar_tmr2
    return

    
reiniciar_tmr2:
    banksel TMR2    
    
    ;movlw   122
    ;movwf   TMR2    
    
    bcf	    TMR2IF
    return
    
    
config_int:
    banksel INTCON
    bsf	    GIE		;GIE=1 habilitar las interrupciones globales
    
    bsf	    T0IE	;T0IE=1 habilitar interrupciones Timer0
    bcf	    T0IF	;apagar la bandera del tmr0
    
    bsf	    PEIE
    banksel PIE1
    bsf	    TMR2IE
    bsf	    TMR1IE
    
    ;banksel PIR1
    ;bcf	    TMR2IF
    ;bcf	    TMR1IF
    
    
    return   
    
    
END