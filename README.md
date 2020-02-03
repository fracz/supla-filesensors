# SUPLA-FILESENSORS

This is a fork of [`supla-dev`](https://github.com/SUPLA/supla-core/tree/master/supla-dev)
that is able to read measurement values from files and send them to the SUPLA, so you can
display them in the app, create direct links etc.

If you can save a measurement in the file, this project will allow you to display it in 
the SUPLA.

If you want to use it, you can have your SUPLA account on official public `cloud.supla.org` service, 
but you need some machine to run `supla-filesensors` for you. It may be anything running linux, 
e.g. RaspberryPi or any Raspberry-like creation, VPS, your laptop etc.

# Supported sensors

* `TEMPERATURE` - sends a value from file as a temperature (channel type pretends to be a DS18B20 thermometer)
* `TEMPERATURE_AND_HUMIDITY` - sends two values for a temperature and humidity (channel type: DHT-22)
* **SOMEDAY**: `HUMIDITY` - sends a single value as a humidity (no corresponding hardware, but does not display any unit in the SUPLA app)
* **SOMEDAY**: `GENERAL` - sends a single value to the [general purpose measurement channel type](https://forum.supla.org/viewtopic.php?f=17&t=5225) (to be released in the next upcoming SUPLA release)

Do not be mistaken that it can send only temperature and humidity values. It can be anything (see examples below).
However, while waiting for the general purpose measurement channel in SUPLA, we must pretend these values are
either temperature or humidity although they can mean completely different thing to you. Setting appropriate icon 
and description should help.


# Installation

```
sudo apt-get install -y git libssl-dev build-essential
git clone https://github.com/fracz/supla-filesensors.git
cd supla-filesensors
./install.sh
```

### Upgrade

```
cd supla-filesensors
git pull
./install.sh
```

# Configuration

There is a `supla-filesensors.cfg` file created for you after installation.
In the `host`, `ID` and `PASSWORD` fields you should enter valid SUPLA-server
hostname, identifier of a location and its password. After successful lauch of the
`supla-filesensors` it will create a device in that location.

Then you can put as many channels in this virtual device as you wish, 
following the template:

```
[CHANNEL_X]
type=TEMPERATURE
file=/home/pi/supla-filesensors/var/raspberry_sdcard_free.txt
min_interval_sec=300
```

* `CHANNEL_X` should be the next integer, starting from 0, e.g. `CHANNEL_0`, `CHANNEL_1`, ..., `CHANNEL_9`
* `type` should be set to one of the supported values mentioned above (depending on the way of presentation you need)
* `file` should point to an absolute path of the file that will contain the measurements
* `min_interval` is a suggestion for the program of how often it should check for new measurements in the
  file; it is optional with a default value of `10` (seconds); if the measurement does not change often, it's
  good idea to set a bigger value not to stress your sd card with too many reads

## What the file with a measurement should look like?

It should just contain the value(s) to send to the SUPLA.

So, for all channels that expect only one value (e.g. `TEMPERATURE`) it should be just number, e.g.

```
13.64
```

For the `TEMPERATURE_AND_HUMIDITY` which expects two values, put them in separate lines, e.g.:

```
88.23
13.2918
```

That's it. Now, it's your job to fill these files with something interesting :-)

# Lauching

Execute the following command in the project directory:

```
./supla-filesensors
```

All parameters that works for [`supla-dev`](https://github.com/SUPLA/supla-core/tree/master/supla-dev)
works here, too. So you can use `-c` to specify different config path or `-d` to start as a deamon.

Do not forget to turn on the new devices registartion, and set appropriate function to the channel 
in SUPLA Cloud.

## Autostarting

Autostart configuration is just the same as the [`supla-dev`](https://github.com/SUPLA/supla-core/blob/8afbd0a0ab9ad9ebf82b7c67d5ccea3618bf23cb/supla-dev/README.md#configure-autostart) instructions.
It's good idea to configure it so `supla-filesensors` starts automatically after your machine boots.

# Where are the sources?

You might have noticed that this repository contains released `supla-filesensors` executables only. 
If you want to see the sources or build them on your own, check out the 
[`supla-filesensors` branch on mine `supla-core`'s fork](https://github.com/fracz/supla-core/tree/supla-filesensors/supla-dev).

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

Then add a `TEMPERATURE_AND_HUMIDITY` channel in `supla-filesensors.cfg` pointing at the `/home/pi/airly.txt`.

### Forecast

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
