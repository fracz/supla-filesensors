# SUPLA-DEV-FILES

This is a fork of [`supla-dev`](https://github.com/SUPLA/supla-core/tree/master/supla-dev)
that is able to read measurement values from files and send them to the SUPLA, so you can
display them in the app, create direct links etc.

If you can save a measurement in the file, this project will allow you to display it in 
the SUPLA.

Currently, it supports only a few channel types. In the nearest major release of SUPLA 
it will support the 
[general purpose measurement channel type](https://forum.supla.org/viewtopic.php?f=17&t=5225) 
which will allow you to display any measurement in whatever format and unit.

# Installation

TODO

# Where are the sources?

This repository contains released `supla-dev-files` executables only. 
If you want to see the sources or build them on your own, check out the 
[`supla-dev-files` branch on mine `supla-core`'s fork](https://github.com/fracz/supla-core/tree/supla-dev-files/supla-dev).

# What can I do?

## Read measurements from Bluetooth devices

### Xiaomi LYWSD03MMC

Download `LYWSD03MMC.py` script from https://github.com/JsBergbau/MiTemperature2 and make it
saving the readings to a file. Use this file to send values to the SUPLA pretending it is
a DHT-22 sensor.

Example installation:

```
mkdir mi-temp
cd mi-temp
wget https://raw.githubusercontent.com/JsBergbau/MiTemperature2/master/LYWSD03MMC.py
echo '#!/bin/bash' > save-fo-file.sh
echo 'echo $3 > sensor_$2.txt' >> save-fo-file.sh
echo 'echo $4 >> sensor_$2.txt' >> save-fo-file.sh
chmod +x LYWSD03MMC.py save-fo-file.sh
```

Now, detect the IP address of the sensor by executing:

```
sudo hcitool lescan
```

And then read its measurements:

```
./LYWSD03MMC.py --device A4:C1:38:2B:99:64 --round --debounce --name mysensor --callback save-fo-file.sh
```

The terminal should show you the measurements repeatedly. Stop it with <kbd>Ctrl</kbd>+<kbd>C</kbd>.
Take a look at the `sensor_mysensor.txt` file. It should contain measurements last seen by the script.

If it works, add a `DHT22` channel configuration to the `supla.cfg`

```
[CHANNEL_0]
type=AM2302
file=/home/pi/mi-temp/sensor_mysensor.txt
```

Last but not least, add the following configuration to the `supervisor` that will take care
about running the reading script for you.

```
[program:mi-temp-1]
command=python3 ./LYWSD03MMC.py --device A4:C1:38:2B:99:64 --round --debounce --name mysensor --callback save-to-file.sh
directory=/home/pi/mi-temp
autostart=true
autorestart=true
user=pi
```

Restart supervisor. It should restart `supla-dev-files` and start the script so you should see 
measurements in the SUPLA app. Do not forget to turn on the new devices registartion, and set
appropriate function to the channel in SUPLA Cloud.

#### If you have more than one sensor

1. Duplicate the `supervisor` config for reading script with different name (e.g. `[program:mi-temp-2]`)
1. Change the `--name mysensor` to something different (e.g. `--name livingroom`)
1. Add new channel in the `supla.cfg` pointing at the file with the measurement name (e.g. `/home/pi/mi-temp/sensor_livingroom.txt`)
1. Restart supervisor.
