//******************************************************************************
// Archivo: main.c
// Autor: Axel Mazariegos
// Fecha: 18 - abril - 2021
// Laboratorio 7 - Programación en C
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

#define _XTAL_FREQ 4000000

//******************************************************************************
// Variables
//******************************************************************************
uint8_t v_tmr0;      //banderas para el anti rebote de cada una de los botones
uint8_t count;       //contador de pulsos de cada boton
uint8_t b_inc;
uint8_t b_dec;
uint8_t numero;
uint8_t centenas;
uint8_t decenas;
uint8_t unidades;
uint8_t segU;
uint8_t segD;
uint8_t segC;
uint8_t banderaT0;




//******************************************************************************
// Prototipos de funciones
//******************************************************************************
void setup(void);       //Funcion para definir la configuracion inicial
void decimales(void);
uint8_t Config_7(uint8_t numero7);
void display3(void);

//******************************************************************************
// Vector de interrupción
//******************************************************************************
void __interrupt() ISR(void){
    
    // INTERRUPT ON CHANGE 
    if (INTCONbits.RBIF)   
    {
        if (PORTBbits.RB0 == 1) {b_inc = 1;}
        if (PORTBbits.RB0 == 0 && b_inc == 1) 
            { 
                b_inc = 0;      
                PORTC++;        
            }                   

        if (PORTBbits.RB1 == 1){b_dec = 1;}
        if (PORTBbits.RB1 == 0 && b_dec == 1) 
            {
                b_dec = 0;       
                PORTC--;          
            }  

        INTCONbits.RBIF = 0;   
    }
    
    // INTERRUPCION DEL TIMER0
    if (INTCONbits.T0IF)
    { 
        banderaT0++;            //incrementar una bandera
        INTCONbits.T0IF = 0;    //apagar la bandera del Timer0
        TMR0 = v_tmr0;          //reiniciar Timer0
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
        
    decimales(); //convertir a decimal
    
    display3();   //mostrar el valor en el 7 segmentos
    
    }
}

//******************************************************************************
// Configuración
//******************************************************************************

void setup(void) {
    
    // CONFIGURACION INICIAR
    v_tmr0 = 236; // para 5 ms 236
    
    // ENTRADAS Y SALIDAS
    TRISA = 0;  // TODO A OUTPUT
    PORTA = 0;  // TODA A APAGADO 
    TRISB=0xFF; // TODO B INPUT
    PORTB = 0;  // TODA B APAGADO
    TRISC = 0;  // TODO C OUTPUT
    PORTC = 0;  // TODA C APAGADO
    TRISD = 0;  // TODO D OUTPUT
    PORTD = 0;  // TODO D APAGADO
    TRISE = 0;  // TODO E OUTPUT
    PORTE = 0;  // TODA E APAGADO
    ANSEL = 0;  // PARA NO USARLO COMO ANALOGICO
    ANSELH = 0; // PARA NO USARLO COMO ANALOGICO
    
    
    // INTERRUPCIONES
    INTCONbits.GIE = 1;  //Habilitar Interrupciones Globales
    INTCONbits.RBIE = 1; //Habilitar IOC
    INTCONbits.T0IE = 1; //Habilitar Interrupciones Timer0
    
    INTCONbits.RBIF = 0; //Apagar bandera IOC
    INTCONbits.T0IF = 0; //Apagar bandera Timer0
   
    IOCBbits.IOCB0 = 1; //Interrupt-on-change enabled PB0
    IOCBbits.IOCB1 = 1; //Interrupt-on-change enabled PB1
    
    
    // CONFIGURACION TIMER0
    OPTION_REGbits.T0CS = 0; //Oscilador interno
    OPTION_REGbits.PSA = 0;  //Habilitar Prescaler
    OPTION_REGbits.PS2 = 1;  //Prescaler 111 = 256
    OPTION_REGbits.PS1 = 1;  
    OPTION_REGbits.PS0 = 1;  
    TMR0 = v_tmr0;           //Reiniciar Timer0 
            
}

//******************************************************************************
// Funciones
//******************************************************************************

void decimales(void)
{
    //convierte un valor en binario de 8 bits (en el PUERTO C)
    //a decimal de tres digitos (centenas, decenas, unidades)
    
    numero = PORTC;
    centenas = numero / 100;
    numero = numero - (centenas*100);
    decenas = numero / 10;
    unidades = numero - (decenas*10);

}


uint8_t Config_7(uint8_t numero7)
{
    //recibe un valor de 8 bits que se desea ver en el 7 segmentos
    //devulve el valor apropiado para usar en un 7 segmentos
    
    uint8_t valor, seg;
    seg = numero7;
    
    switch(seg)
    {
        case 0:
            valor= 0b00111111;
            break;
        case 1:
            valor= 0b00000110;
            break;
        case 2:
            valor= 0b01011011;
            break;
        case 3:
            valor= 0b01001111;
            break;
        case 4:
            valor= 0b01100110;
            break;
        case 5:
            valor= 0b01101101;
            break;
        case 6:
            valor= 0b01111101;
            break;
        case 7:
            valor= 0b00000111;
            break;
        case 8:
            valor= 0b01111111;
            break;
        case 9:
            valor= 0b01101111;
            break;
        case 10:
            valor= 0b01110111;
            break;
        case 11:
            valor= 0b01111100;
            break;
        case 12:
            valor= 0b00111001;
            break;
        case 13:
            valor= 0b01011110;
            break;
        case 14:
            valor= 0b01111001;
            break;
        case 15:
            valor= 0b01110001;
            break;     
    }
    return valor;
}


void display3(void)
{
    //muestra el valor del numero en decimal en 3 7segmentos
   
    switch(banderaT0)
    {
        case 1:
            PORTD = 0;      //Borrar el Puerto D
            PORTE = 0x01;   //Habiliar el 7seg
            segU = Config_7(unidades);  //busacar el valor del 7seg
            PORTD = segU;   //Mostrar el valor en el 7seg
            break;
            
        case 2:
            PORTD = 0;
            PORTE = 0x02;
            segD = Config_7(decenas);
            PORTD= segD;
            break;
            
        case 3:
            PORTD = 0;
            PORTE = 0x04;
            segC = Config_7(centenas);
            PORTD= segC;
            banderaT0 = 0;
            break;
    }
    
}