# Accounting of Assumptions: Weather-based NeoPixel Ring
#### CS 278-1 Final | Project Gimli
#### Authors: Wes and Cade
#### Date: 5/16/2023
---
## Assumptions:
    1. ASSUMPTION: Weather input is provided to the microcontroller in a format that can be interpreted by 
                   the code.
       Justification: The code assumes that the weather input is correctly formatted and provided to
       the microcontroller in a way that can be processed and interpreted by the code logic.

    2. ASSUMPTION: The provided weather conditions (clear, overcast, showers, and thunderstorms) are
                  sufficient for the project's requirements.
       Justification: The code is designed to work with a specific set of weather conditions. Additional
                     or different weather conditions would require modifications to the code.
    
    3. ASSUMPTION: The code operates within the memory and processing capabilities of the microcontroller.
       Justification: The code assumes that it can be executed within the memory limitations and processing
                      capabilities of the chosen microcontroller. Consideration should be given to
                      potential memory constraints and optimizations.
    
    4. ASSUMPTION: The communication speed between python script and ATmega would be equal
       JUSTIFICATION: We needed to adjust the rate at which data was being transferred between the two
                      devices through the use of nops or time.sleep() function in python to ensure smooth
                      communication between the two devices.

    5. ASSUMPTION: Animating the LEDs would only require simply timing control
       JUSTIFICATION: It was a lot more complex than this. We initially tried to just use a wait subroutine.
                      but the way we developed and implemented our code to output to LEDs limited this.
                      functionality.

    6. ASSUMPTION: Messages scraped from the web would be readable by board
       JUSTIFICATION: Originally, we thought that we would be able to just scrape the information we needed
                      and send it straight to the board, but that wasn’t the case. We had to import some python libraries to easily convert each message into something readable for the board.
    
    7. ASSUMPTIONS: Color/brightness of LEDs would be easy on the eyes
       JUSTIFICATION: It was not... to fix this we added a few lsr instructions to effectively
                      turn down the brightness so you can actually look at the lights.
