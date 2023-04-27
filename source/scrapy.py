# CS 278-1 Final Project
# Authors: Wes and Cade
#
# Description:
# ------------
# WebScraper used to capture Data from...
#
# Resources:
# ----------
# 


# --------------
# PROGRAM START:
# --------------
#from selenium import webdriver
#from selenium.webdriver.common.by import By
import serial

# set the path to the Edge driver executable file
#edge_driver_path = "edgedriver_win64\msedgedriver.exe"

# create an instance of the Edge driver
#driver = webdriver.Edge(executable_path=edge_driver_path)

# navigate to a weather.gov spokane washingtons page
#driver.get("https://forecast.weather.gov/MapClick.php?x=210&y=120&site=otx&zmx=&zmy=&map_x=209&map_y=120#.ZElK5c7MLl0") 

# extract some information from the website using Selenium
#todaysTemp = driver.find_element(By.CLASS_NAME, "myforecast-current-lrg") # Looks for the current temp of Spokane in F
#todaysTemp_text = todaysTemp.text                                      # Transfers that data into text for printing
#todaysWeather = driver.find_element(By.CLASS_NAME, "myforecast-current")
#todaysWeather_text = todaysWeather.text               

#print("WEATHER: ", todaysWeather_text)
#print("TEMP: ", todaysTemp_text)                                          # Prints the data to terminal to see if it is correct


# close the browser window when done
#driver.quit()

# replace 'COM4' with the actual COM port number
ser = serial.Serial('COM4', 9600)

# send data over USART
ser.write(b'\x50')

# close the serial port
ser.close()


