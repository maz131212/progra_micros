//******************************************************************************
// Archivo: main.c
// Autor: Axel Mazariegos
// Fecha: 27 - abril - 2021
// Laboratorio 9 - PWM
//******************************************************************************


//******************************************************************************
// Importación de Librerías
//******************************************************************************
#include <xc.h>
#include <stdint.h>


//******************************************************************************
// Palabra de configuración
//******************************************************************************

// CONFIG1
#pragma config FOSC = XT        // Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

#define _XTAL_FREQ 8000000

//******************************************************************************
// Variables
//******************************************************************************

uint8_t bandera;



//******************************************************************************
// Prototipos de funciones
//******************************************************************************
void setup(void);       //Funcion para definir la configuracion inicial


//******************************************************************************
// Vector de interrupción
//******************************************************************************
void __interrupt() ISR(void){
    
    // INTERRUPCION DEL ADC
    if (PIR1bits.ADIF)
    { 
        switch(bandera){
            case(0):
                CCPR1L = (ADRESH>>1)+124;
                PIR1bits.ADIF = 0;  
                bandera = 1;
                ADCON0bits.CHS = 1; //AN1 en el PORTA1
                break;
            case(1):
                CCPR2L = (ADRESH>>1)+124;
                PIR1bits.ADIF = 0;
                bandera = 0;
                ADCON0bits.CHS = 0; //AN0 en el PORTA0
                break;
            }
    }
}

//******************************************************************************
// Ciclo Principal
//******************************************************************************

void main(void) 
{

    setup();    //configuracion

    //**************************************************************************
    // Loop Principal
    //**************************************************************************

    while (1) 
    {
        
    ADCON0bits.GO_DONE = 1;
    __delay_us(50);
    
    }
}

//******************************************************************************
// Configuración
//******************************************************************************

void setup(void) {
    
    // ENTRADAS Y SALIDAS
    TRISA = 3;  // TODO A
    PORTA = 0;  // TODA A APAGADO 
    TRISB = 0;  // TODO B OUTPUT
    PORTB = 0;  // TODA B APAGADO
    TRISC = 0;  // TODO C OUTPUT
    PORTC = 0;  // TODA C APAGADO
    TRISD = 0;  // TODO D OUTPUT
    PORTD = 0;  // TODO D APAGADO
    TRISE = 0;  // TODO E OUTPUT
    PORTE = 0;  // TODA E APAGADO
    ANSEL = 0x03;  // PARA USARLO COMO ANALOGICO
    ANSELH = 0; // PARA NO USARLO COMO ANALOGICO
    
    // OSCILADOR
    //OSCCONbits.IRCF = 0b0111; //8MHz
    //OSCCONbits.SCS = 1;
    
    
    // INTERRUPCIONES
    PIR1bits.ADIF = 0;  //Limpiar la bandera de interrupcion ADC
    PIE1bits.ADIE = 1;  //Habilitar la interrupcion ADC
    
    INTCONbits.PEIE = 1; //Habilitar interrupciones Perifericas
    INTCONbits.GIE = 1;  //Habilitar Interrupciones Globales
    
    
    // CONFIGURACION DEL PWM
    TRISCbits.TRISC2 = 1;   // RC2/CCP1 como entrada
    PR2 = 255;              // configuracion del periodo
    CCP1CONbits.P1M = 0;    // configurar modo PWM -- Single output
    
    CCP1CONbits.CCP1M = 0b1100; //PWM mode
    
    CCP2CONbits.CCP2M = 0b1100; //PWM mode
    
    CCPR1L = 0x0F;      // Dar un valor inicial
    CCPR2L = 0x0F;      // Dar un valor inicial
    CCP1CONbits.DC1B = 0;
    CCP2CONbits.DC2B1 = 0;
    CCP2CONbits.DC2B0 = 0;
    
    PIR1bits.TMR2IF = 0;        // Apagar bandera Timer2
    T2CONbits.T2CKPS = 0b11;    // Prescaler 1:16
    T2CONbits.TMR2ON = 1;
    
    while (PIR1bits.TMR2IF == 0);   // Esperar 1 ciclo
    PIR1bits.TMR2IF = 0;        // Apagar bandera Timer2

    TRISCbits.TRISC2 = 0;   // Salida del PWM
    
    
    // CONFIGURACION MODULO ADC
    ADCON0bits.ADCS1 = 1;
    ADCON0bits.ADCS0 = 0;    
    
    ADCON1bits.VCFG0 = 0;
    ADCON1bits.VCFG1 = 0;

    ADCON1bits.ADFM = 0; //Justificado a la izquierda
    
    ADCON0bits.ADON = 1;
    
    ADCON0bits.CHS = 0; //AN0 en el PORTA0
    __delay_us(50);
    
    ADCON0bits.GO_DONE = 1;
    __delay_ms(5);
       
}

//******************************************************************************
// Funciones
//******************************************************************************
