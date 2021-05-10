//******************************************************************************
// Archivo: main.c
// Autor: Axel Mazariegos
// Fecha: 04 - may0 - 2021
// Laboratorio 10 - UART
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
#pragma config FOSC = INTRC_NOCLKOUT    // Oscillator Selection bits
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
char caracter;
char recibido;
uint8_t bandera;


//******************************************************************************
// Prototipos de funciones
//******************************************************************************
void setup(void); //Funcion para definir la configuracion inicial
void mostrar(char caracter);
char recibir();
void cadena(char *direccion);

//******************************************************************************
// Vector de interrupción
//******************************************************************************

void __interrupt() ISR(void) {

}

//******************************************************************************
// Ciclo Principal
//******************************************************************************

void main(void) {

    setup(); //configuracion

    //**************************************************************************
    // Loop Principal
    //**************************************************************************

    while (1) {
        cadena("\r Que accion desea ejecutar? \r");
        cadena(" 1) Desplegar cadena de caracteres \r");
        cadena(" 2) Cambiar PORTA \r");
        cadena(" 3) Cambiar PORTB \r ");

        bandera = 1;

        while (bandera) {

            while (PIR1bits.RCIF == 0); //Esperar a recibir dato

            caracter = recibir();

            switch (caracter) {
                case ('1'):
                    cadena("\r Hola mundo \r");
                    bandera = 0;
                    break;

                case ('2'):
                    cadena("\r Ingrese un caracter para el puerto A: ");
                    while (PIR1bits.RCIF == 0); //Esperar
                    PORTA = recibir(); //Pasar el valor al puerto A
                    mostrar(recibido); //mostrar el caracter en la pantalla
                    cadena("\r Listo \r");
                    bandera = 0;
                    break;

                case ('3'):
                    cadena("\r Ingrese un caracter para el puerto B: ");
                    while (PIR1bits.RCIF == 0); //Esperar
                    PORTB = recibir(); //Pasar el valor ap puerto B
                    mostrar(recibido); //mostrar el caracter en la pantalla
                    cadena("\r Listo \r");
                    bandera = 0;
                    break;

                default:
                    cadena("!!!!!!!!ERROR!!!!!!! \r");
                    cadena(" Debe ingresar solo '1' '2' o '3' \r");
            }
        }

    }
}

//******************************************************************************
// Configuración
//******************************************************************************

void setup(void) {

    // ENTRADAS Y SALIDAS
    TRISA = 0; // TODO A OUTPUT
    PORTA = 0; // TODA A APAGADO 
    TRISB = 0; // TODO B OUTPUT
    PORTB = 0; // TODA B APAGADO
    TRISC = 0; // TODO C OUTPUT
    TRISCbits.TRISC7 = 1;
    PORTC = 0; // TODA C APAGADO
    TRISD = 0; // TODO D OUTPUT
    PORTD = 0; // TODO D APAGADO
    TRISE = 0; // TODO E OUTPUT
    PORTE = 0; // TODA E APAGADO
    ANSEL = 0; // PARA NO USARLO COMO ANALOGICO
    ANSELH = 0; // PARA NO USARLO COMO ANALOGICO

    // OSCILADOR
    OSCCONbits.IRCF = 0b0111; //8MHz
    OSCCONbits.SCS = 1;

    /*
    // INTERRUPCIONES
    PIR1bits.RCIF = 0;  //Limpiar la bandera 
    PIE1bits.RCIE = 1;  //Habilitar la interrupcion 
    PIE1bits.TXIE = 1;
    
    INTCONbits.PEIE = 1; //Habilitar interrupciones Perifericas
    INTCONbits.GIE = 1;  //Habilitar Interrupciones Globales
     */


    // COMUNICACION SERIAL
    TXSTAbits.SYNC = 0; //asincrono
    TXSTAbits.BRGH = 1; //high speed
    BAUDCTLbits.BRG16 = 1; //uso los 16 bits

    SPBRG = 207; //Fosc 8MHz Baud Rate 1202 Error 0.16%                      
    SPBRGH = 0;

    RCSTAbits.SPEN = 1; //enciendo el modulo
    RCSTAbits.RX9 = 0; //No trabajo a 9 bits
    RCSTAbits.CREN = 1; //activo recepción
    TXSTAbits.TXEN = 1; //activo transmision 

}

//******************************************************************************
// Funciones
//******************************************************************************

void mostrar(char caracteres) {
    while (TXSTAbits.TRMT == 0);
    TXREG = caracteres;
}

char recibir() {
    recibido = RCREG;
    return recibido;
}

void cadena(char *direccion) {
    while (*direccion != '\0') {
        mostrar(*direccion);
        direccion++;
    }
}