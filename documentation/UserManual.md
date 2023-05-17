# User Manual: Weather-based NeoPixel Ring
#### CS 278-1 Final | Project Gimli
#### Authors: Wes and Cade
#### Date: 5/16/2023
---
## Introduction (What You need):
    This user manual provides instructions on how to use the weather based NeoPixle ring. The code is written in assembly language and is designed to control the colors of LEDs based on different weather conditions and temperature received from a python web scraper.

### Hardware Requirements:
    Microcontroller board supporting the assembly language code.
    NeoPixel Ring - 24 x 5050 RGB LED with Integrated Drivers connected to PORTD on ATmega.
    Additional hardware components as required by the specific microcontroller setup.

### Software Requirements:
    Assembler compatible with the microcontroller's assembly language.
    Programming software or environment for uploading the compiled code to the microcontroller.
    Ability to run python scripts.
---

## Steps (How to Run):
    1. Make sure the setup from above is correct for your system 
   
    2. Go into Scrapy.py file:
        Note:
        - The first part of this file will be used to grab the information for weather.gov
        - Line 54 and 55 determine what information you are scraping (Weather type or temp)
        - Using that code, you can add more lines like it to get more info. Make sure you know the html.
          element it is one the website though.

    3. Set code to your specifications

    4. Plug in properly wired ATmega and NeoPixel Ring
   
    5. Run the python file scrapy.py
---

## FAQ:
    Q2: What hardware do I need for this project?
    A: You will need an ATmega328p. Additionally, you will need NeoPixel Ring - 24 x 5050 RGB LED with Integrated Drivers connected properly wired to the board on PORTD

    Q4: How do I set up the code on my microcontroller?
    A: To set up the code on your microcontroller, follow these steps:

        -Connect the LEDs to the appropriate output pins of the microcontroller.
        - Compile the provided assembly language code using a compatible assembler.
        - Upload the compiled code to the microcontroller using programming software or an 
          environment compatible with your microcontroller.

    Q5: How do I provide weather input to the microcontroller?
    A: Yes, this will require you to do a little bit of coding to get everything setup, but it is possible. See step two in how to run for more information.

    Q6: How do I troubleshoot issues with the LED control?
    A: If you encounter issues or unexpected behavior, consider the following steps:

        - Check hardware connections to ensure the LEDs are properly connected.
        - Verify the weather input provided to the microcontroller.
        - Utilize debugging tools or a debugger if available to identify any issues in the code.
        - Consult documentation related to your microcontroller or the code for troubleshooting guidance.
  
    Q7: Can I add more weather types or customize the color patterns?
    A: The provided code supports a specific set of weather types (clear, overcast, showers, and thunderstorms). To add more weather types or customize color patterns, you will need to modify the code accordingly. Considerations such as memory limitations and the capabilities of your microcontroller should be considered.

    Q8: Is this code portable to different microcontrollers?
    A: The code may require modifications to be compatible with different microcontrollers due to variations in assembly language, pin mappings, and hardware configurations. Portability will depend on the specific microcontroller and its compatibility with the code.

    Q9: How can I further enhance this project?
    A: To enhance the project, you can ad whatever your heart desires.

    Q10: Can I use higher-level programming languages instead of assembly language?
    A: Yes, it is possible to implement weather-based LED control using higher-level programming languages such as C or Python. However, you would need to rewrite the code in the desired programming language and adapt it to the specific features and capabilities of the chosen language and microcontroller.
