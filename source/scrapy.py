# CS 278-1 Final Project
# Authors: Wes and Cade
#
# Description:
# ------------
# WebScraper used to capture Data from weather.gov - Spokane tab
#
# Resources:
# ----------
# https://pypi.org/project/selenium/
# https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/
# https://www.geeksforgeeks.org/selenium-python-tutorial/
# https://docs.python.org/3/library/re.html
# https://docs.python.org/3/library/time.html
# Scott Office Hours 
# https://whitgit.whitworth.edu/2023/spring/CS-278-1/in_class/-/blob/main/Directives_EEPROM_class/source/mem_testing_solution.asm


# --------------
# PROGRAM START:
# --------------
from selenium import webdriver                                      # Used to open and search webpages
from selenium.webdriver.support.ui import WebDriverWait             # Used to access the webdriverwait class and functionality
from selenium.webdriver.support import expected_conditions as EC    # Used for wait function - allow us to ensure webpage has loaded
from selenium.webdriver.common.by import By                         # Used for searching webpages by their HTML or CSS elements
import serial                                                       # Used for webscraping
import re                                                           # Used to format and edit strings of information
import time                                                         # Used to time the process of sending information
import array                                                        # Used to work with arrays
import random                                                       # Used to select random indexs from arrays
import struct


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SCRAPE FOR INFO:
# ----------------
edge_driver_path = "edgedriver_win64\msedgedriver.exe"                                                                   # set the path to the Edge driver executable file

# Set the options for running the browser in headless mode
options = webdriver.EdgeOptions()
options.add_argument('headless')                                                                                         # Stops the webpage window from appearing every time script runs

# Create an instance of the Edge driver with headless options
driver = webdriver.Edge(executable_path=edge_driver_path, options=options)                                             
driver.get("https://forecast.weather.gov/MapClick.php?x=210&y=120&site=otx&zmx=&zmy=&map_x=209&map_y=120#.ZElK5c7MLl0")  # navigate to a weather.gov spokane washingtons page

# Wait for the temperature element to appear for a maximum of 4 seconds
# Allows us to ensure webpage is loaded fully before we grab the info
element = WebDriverWait(driver, 4).until(
    EC.presence_of_element_located((By.CLASS_NAME, "myforecast-current-lrg"))
)

# Extract some information from the website using Selenium
todaysTemp = driver.find_element(By.CLASS_NAME, "myforecast-current-lrg")                                                # Looks for the current temp of Spokane in F
todaysTemp_text = todaysTemp.text                                                                                        # Transfers that data into text for printing        

print("TEMP: ", todaysTemp_text)                                                                                         # Prints the data to terminal to see if it is correct

driver.quit()                                                                                                            # close the browser window when done


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SEND INFO TO CHIP:
# ------------------
ser = serial.Serial('COM4', baudrate=9600, bytesize=8, parity='N', stopbits=2) # replace 'COM4' with the actual COM port number
ser.write(0X00)                                                                # Send a null value to the chip to trigger a reset
time.sleep(2)                                                                  # Wait for the chip to setup before we send any further information (Waits 2 seconds)

# FORMAT TODAYS TEMP:
# -------------------
#  -> Gets TempText ready to be sent to chip to be processed
hex_val =  str(re.findall(r'\d+', todaysTemp_text)[0])            # random.randint(1,116)            # extract the number part from todaysTemp_text
# byte_val = bytes.fromhex(hex_val)                               # Format tempreture into bytes
# print(f"About to send {byte_val.hex()} to Arduino")             # Print todaysTemp to the terminal - testing purposes

todaysTempre = int(hex_val)                                                                                                 # Var to hold todays temp from weather.gov
print(todaysTempre)                                                                                                         # Print the value of todays temp to the terminal
temperatureValues = [24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 116]   # Assigns a value to each neopixel on the ring 
count = 0                                                                                                                   # Set up a count varibale to keep track of amout of LEDs we want turned on
for i in range(len(temperatureValues)):                                                                                     # Loop through every index in pixel array
    if todaysTempre >= temperatureValues[i]:                                                                                # If todays temp is greater or equal to current index
        count += 1                                                                                                          # Increase count by one
    elif todaysTempre < temperatureValues[i]:                                                                               # If todays temp is less than the current index exit
        # print(count)                                                                                                      # Print count to terminal - testing purposes
        count_val = struct.pack('B', count)                                                                                 # Convert count to a single byte
        break


# count_str = hex(count)[2:]  # Convert the value to a string without '0x' prefix
# count_val = bytes.fromhex(count_str)
weatherTypes = ["Clear", "Overcast", "Showers", "T-storms"]     # Creates an array of random weaher types (Used to show how program works with different weather types, weather doesnt change frequently enough) 
random_index = random.randrange(len(weatherTypes))              # Selects a random index/weather type from the array above
random_element = weatherTypes[random_index]                     # Sets random element to the random array index
todaysWeather_text = random_element                             # THen the program assigns that random element as the weather type for that day
print(todaysWeather_text)                                       # Print weather type to the terminal for testing 

# CONFIGURE WEATHER MESSAGE: 
# --------------------------
#  -> Takes the weather type and tempreture and formats it in for the ATmega to process
#  -> A message looks like this, $00 - $Todays Weather type - $Todays Tempreture EX: $00 - $40 - $64
#  -> The message above indicates its thunder storms and currently 64 degreee 
#  -> The $00 value is used to tell the chip to get ready to process information

msgSend = bytes.fromhex('00')           # Sets the value of msgSend to $00 - used before every message 
clv = bytes.fromhex('10')               # Sets a clear weather type to $10
ocv = bytes.fromhex('20')               # Sets a Overcast weather type to $20
shv = bytes.fromhex('30')               # Sets a Showers weather type to $30
tsv = bytes.fromhex('40')               # Sets a Thunder storms weather type to $40

# Each if Statemet below is as follows:
# 1.) Check if WeatherType is X
# 2.) If yes create a message based of that 
# 3.) Send $00
# 4.) Wait to give chip time to process
# 5.) Send weahter type
# 6.) Wait again
# 7.) Send the temp

if todaysWeather_text == "Clear":                   # Check if Clear today
    ser.write(msgSend)                              
    time.sleep(2)                                   
    ser.write(clv)                                  
    time.sleep(2)                                   
    ser.write(count_val)                             
    # print(f"Sent {byte_val.hex()} to Arduino")    # Print value of temp - Testing purposes

elif todaysWeather_text == "Overcast":              # Check if Overcast toady
    ser.write(msgSend)                              
    time.sleep(2)                                  
    ser.write(ocv)                                 
    time.sleep(2)                                  
    ser.write(count_val)                             
    # print(f"Sent {byte_val.hex()} to Arduino")    # Print value of temp - Testing purposes

elif todaysWeather_text == "Showers":               # Check if Rainy
    ser.write(msgSend)
    time.sleep(2)
    ser.write(shv)
    time.sleep(2)
    ser.write(count_val)
    # print(f"Sent {byte_val.hex()} to Arduino")    # Print value of temp - Testing purposes

elif todaysWeather_text == "T-storms":              # Check if Thunderin and Rumblin
    ser.write(msgSend)
    time.sleep(2)
    ser.write(tsv)
    time.sleep(2)
    ser.write(count_val)
    # print(f"Sent {byte_val.hex()} to Arduino")    # Print value of temp - Testing purposes
ser.close()                                         # close the serial port
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------