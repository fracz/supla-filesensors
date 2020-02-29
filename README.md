# SUPLA-FILESENSORS

[![SUPLA Filesensors](https://img.youtube.com/vi/y1HHho2qSDE/0.jpg)](https://youtu.be/y1HHho2qSDE)

This project has been completely replaced by the [`supla-virtual-device`](https://github.com/lukbek/supla-virtual-device).
Go there for installation and running instructions.

This readme still serves as a source of ideas of what you can save to a file and display in SUPLA.

# What can I do?

You need to find a way of putting meaningful numbers into the files mentioned in the
channels configuration. Thay can come from anywhere and mean anything. It's totally up to you.

I will post some examples here just to make you aware of what and how can be accomplished. But the
main idea often boils down to one of these patterns:

* get the value periodically at specific intervals; this involves executing your command that puts new
  values in monitored values with [cron](https://en.wikipedia.org/wiki/Cron)
* get the value continously with a process that is constantly run; such process should be configured
  similarily to the [`supla-dev` or `supla-filesensors`](https://github.com/SUPLA/supla-core/blob/8afbd0a0ab9ad9ebf82b7c67d5ccea3618bf23cb/supla-dev/README.md#configure-autostart)
  with `init.d` or `supervisor`; I will post `supervisor` configuration examples below

So let's proceed with the examples!

## Read some interesting APIs out there

There are plenty of public APIs that offer some interesing data you might want to display and 
use in SUPLA. They are often available in `JSON` format so you will need a [`jq`](https://stedolan.github.io/jq/)
tool to read them. Go ahead and install it.

```
sudo apt-get install jq
```

And explore!

### Airly

![AIRLY image](https://raw.githubusercontent.com/fracz/supla-filesensors/master/img/airly.png)

Airly publishes air quality and some weather conditions as a public API. You need to generate an API key
and know the coordinations of where you live and you can fetch the data it publishes, save it in a file...
And display in SUPLA :-)

See an example URL (it will not work because of invalid API Key):

```
https://airapi.airly.eu/v2/measurements/nearest?lat=51.038900&lng=19.13251&maxDistanceKM=10&apikey=CBKndj3UVtGpAGlmLFiAL4wLekYo
```

Change the coordinates and API Key to your data and see the output. You can easily consume it and save the
PM10 and PM2.5 values in a file with the following crontab:

```
*/10 * * * * (AIRLY_DATA=$(curl -s 'https://airapi.airly.eu/v2/measurements/nearest?lat=51.038900&lng=19.13251&maxDistanceKM=10&apikey=CBKndj3UVtGpAGlmLFiAL4wLekYo') && echo $AIRLY_DATA | jq '.current.values[] | select(.name=="PM10") | .value' && echo $AIRLY_DATA | jq '.current.values[] | select(.name=="PM25") | .value') > /home/pi/airly.txt
```

### Syngeos
Syngeos like Airly, publish data on air quality, pressure etc.
There is no need to generate an API key here.
All you have to do is go to the page [Syngeos Map](https://panel.syngeos.pl/sensor/pm10) and select the sensor you are interested in.
An example for Wojkowice: 

```
https://panel.syngeos.pl/sensor/pm10?device=187
```

Add the crontab below and change the final digit of the address (187) to the sensor of your choice

```
*/10 * * * * (SYNGEOS_DATA=$(curl -s 'https://api.syngeos.pl/api/public/data/device/187') && echo $SYNGEOS_DATA | jq '.sensors[4] | select(.name=="pm10") | .data[0].value' && echo $SYNGEOS_DATA | jq '.sensors[3] | select(.name=="pm2_5") | .data[0].value') > /home/pi/syngeos-air.txt
```

For atmospheric pressure:

```
*/10 * * * * (SYNGEOS_DATA=$(curl -s 'https://api.syngeos.pl/api/public/data/device/187') && echo $SYNGEOS_DATA | jq '.sensors[2] | select(.name=="air_pressure") | .data[0].value') > /home/pi/syngeos-pressure.txt
```

### Forecast

![Forecast image](https://raw.githubusercontent.com/fracz/supla-filesensors/master/img/forecast.png)

#### OpenWeatherMap

It's quite easy to get forecast info with [OpenWeatherMap API](https://openweathermap.org/api).
You need to sign in and get your APP ID, but then you are good to go and consume the API.
For example, you can display the anticipated temperature that will be at your location
in e.g. 6 hours with the [5 days forecast endpoint](https://openweathermap.org/forecast5).

```
0 0 * * * curl -s 'http://api.openweathermap.org/data/2.5/forecast?q=Paczków,pl&units=metric&appid=YOUR_API_KEY' | jq '.list[1].main.temp'
```

### Github

How many commits SUPLA developers made in the last week? Are they working at all?

```
0 0 * * * curl -s 'https://api.github.com/repos/SUPLA/supla-cloud/stats/commit_activity' | jq '.[0].total' > /home/pi/supla-progress.txt
```

![Github image](https://raw.githubusercontent.com/fracz/supla-filesensors/master/img/commits.png)

## Get measurements from HTML / XML pages

In order to consume HTML/XML output nicely, it's good idea to use [CSS selectors](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Selectors). Luckily, there is
a [pup](https://github.com/ericchiang/pup) tool that offers CSS selectors in command line. Go to the [pup releases](https://github.com/ericchiang/pup/releases)
and download a binary suitable for your machine. It is also a good idea to move it to `/usr/bin`
so it is globally available as `pup` command. For example, for Raspberry, it would be:

```
sudo apt-get install unzip
wget https://github.com/ericchiang/pup/releases/download/v0.4.0/pup_v0.4.0_linux_arm.zip -O pup.zip
unzip pup.zip
sudo mv pup /usr/bin
rm pup.zip
```

### Display PLN-EUR exchange rate

The exchange rate is for example available
on [https://internetowykantor.pl/kurs-euro/](https://internetowykantor.pl/kurs-euro/).

Looking at the HTML, the interesting part is:

```html
<span class="kurs kurs_sprzedazy">4,2828</span>
```

So we can get this with `pup` and save it in a file for `supla-filesensors` every hour:

```
0 0 * * * curl -s 'https://internetowykantor.pl/kurs-euro/' | pup '.kurs_sprzedazy text{}' | sed 's/,/./' > /home/pi/exchange_rate.txt
```

Also notice how the `sed` is used to replace comma `,` to dot `.` so the SUPLA is not confused with the number format.

## Read measurements from Bluetooth devices

For this you need to have a Bluetooth module on the device you run this program (seems obvious right?).
Raspberry Pi Zero W [is considered to have](https://github.com/JsBergbau/MiTemperature2/issues/3#issuecomment-577148741)
very decent Bluetooth range.

In order to get measurements from any Bluetooth sensor you need to find out it's MAC address.
Therefore, it might be a good idea to start with finding it:

```
sudo hcitool lescan
```

### LYWSD03MMC

![LYWSD03MMC image](https://raw.githubusercontent.com/fracz/supla-dev-files/master/img/LYWSD03MMC.jpg)
![LYWSD03MMC on SUPLA](https://raw.githubusercontent.com/fracz/supla-filesensors/master/img/LYWSD03MMC.png)

Download `LYWSD03MMC.py` script from https://github.com/JsBergbau/MiTemperature2 and 
install all of its [prerequisites](https://github.com/JsBergbau/MiTemperature2#prequisites--requirements).
Then use it to save the readings to a file. Use this file to send values to the SUPLA pretending it is
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

And then read its measurements:

```
./LYWSD03MMC.py --device A4:C1:38:2B:99:64 --round --debounce --name mysensor --callback save-fo-file.sh
```

The terminal should show you the measurements repeatedly. Stop it with <kbd>Ctrl</kbd>+<kbd>C</kbd>.
Take a look at the `sensor_mysensor.txt` file. It should contain measurements last seen by the script in two lines.

Add a `TEMPERATURE_AND_HUMIDITY` channel in `supla-filesensors.cfg` pointing at the resulting file.

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

#### If you have more than one sensor

1. Duplicate the `supervisor` config for reading script with different name (e.g. `[program:mi-temp-2]`)
1. Change the `--name mysensor` to something different (e.g. `--name livingroom`)
1. Add new channel in the `supla.cfg` pointing at the file with the measurement name (e.g. `/home/pi/mi-temp/sensor_livingroom.txt`)
1. Restart supervisor.

## Get anything you can measure

### Show how many storage is left on hard drive

![Pi image](https://raw.githubusercontent.com/fracz/supla-filesensors/master/img/freesd.png)

```
*/30 * * * * df -h --total / | awk '{print $5}' | tail -n 1 > /home/pi/storage.txt
```

# More ideas?

I will be more than happy to accept pull requests with your ideas of what measurements we can
integrate with SUPLA by using this simple tool.
