# How to use sketch_05499Knit
1. Open arduino IDE: File -> Examples -> Firmata -> StandardFirmata and upload the example code to your arduino.
2. Open ``sketch_05499Knit/sketch_05499Knit.pde`` in processing IDE
3. Uncomment ``//println(Arduino.list());`` in ``setup()`` and run the code
4. Replace 2 in the next line with with your arduino board in the printed ``Arduino.list()``
5. A0 is used for the analog pin, so connect your sensor and resistor properly to A0.
6. Run ``sketch_05499Knit/sketch_05499Knit.pde``.
7. Click "START" button to start logging the data.
8. Click "SAVECSV" button to export logged data ``data/resistances.csv``
9. run ``jupyter-notebook`` in ``sketch_05499Knit`` directory
10. open ``dataProcessing.ipynb`` in jupyter-notebook server
11. play with the filters and your data.

# How to set up Arduino for Lilypad USB

## Connect lilypad and set up board 
![IMG_3239](https://user-images.githubusercontent.com/72460026/114313637-35655400-9ac5-11eb-9b05-33df43900e0c.jpg)

## Set up port
Make sure the usb one is selected
![IMG_3240](https://user-images.githubusercontent.com/72460026/114313643-3dbd8f00-9ac5-11eb-88e1-1e6f6f39bc64.jpg)

## Serial monitor
This is where printed statements appear
![IMG_3241](https://user-images.githubusercontent.com/72460026/114313685-7fe6d080-9ac5-11eb-8ccc-bd5e2826f006.jpg)
