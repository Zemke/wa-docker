Worms Armageddon dockerized based on [scottyhardy/docker-wine](https://hub.docker.com/r/scottyhardy/docker-wine) with Worms Armageddon installed using Wine.

The incentive is to use the `WA.exe`‘s command line arguments headlessly in server environments to generate game statistics from replay log files like [this](http://www.normalnonoobs.com/replaydetail/19750_Saint-2-0-Kilobyte-2020-03-08#replaydetail_tab1), [this](https://www.tus-wa.com/cups/game-39341/) or [this](http://wormolympics.com/tournaments/replay_info/33860).

This is productive on https://waaas.zemke.io

## Usage

```
sudo docker run --rm --privileged -v /home/zemke/play/final.WAgame:/tmp/v/game.WAgame -v /home/zemke/Downloads/wa.iso:/tmp/v/wa.iso zemke/docker-wa getlog > game.log
```

Pass the `*.WAgame` file you want to process a volume and mount it to the container’s `/tmp/v` directory. Likewise the disk image is required to run WA. `--priviliged` is required to mount the disk image within the container. The replay log is output to `stdout`.

Alternatively you can pass `getmap` which returns the game’s map file. This can be depending on the replay file a [monochrome map](https://worms2d.info/Monochrome_map_(.bit,_.lev)) `*.lev` file. In future versions of this Docker image one might get the PNG version of that map.

## Under the hood

Basically:  [scottyhardy/docker-wine](https://hub.docker.com/r/scottyhardy/docker-wine) + [Installing WA on Linux](https://worms2d.info/Installing_WA_on_Linux) + [WA Command-Line Options](https://worms2d.info/Command-line_options).

The part that’s tricky is the headlessness. WA in Wine is good and has worked for a long time. The whole thing in Docker—definitely cool. But making this setup work in a server environment is the requirement to have it work alongside another application which wants that replay data.

### Headless

[xvkbd](http://t-sato.in.coocan.jp/xvkbd/) (X Virtual  Keyboard) and [Xvfb](https://en.wikipedia.org/wiki/Xvfb) (X Virtual Framebuffer) are the ingredients to make this setup headless. Xvfb creates a virtual screen that Wine can use which acts like an actual display. `DISPLAY :1` is an environment variable given to the image. `WA.exe /getlog /tmp/v/game.WAgame` is the command-line feature that comes with WA to extract the log. That will actually yield some UI dialogs that are accepted with spammed enter presses using xvkbd.

```
#!/bin/bash

timeout 30s ./perform $@

if [ "$1" = "getlog" ]; then
  cat /tmp/v/game.log
elif [ "$1" = "getmap" ]; then
  cat User/SavedLevels/game.LEV
fi
```

```
#!/usr/bin/bash

mount -o loop,ro /tmp/v/wa.iso /mnt/wa
Xvfb :1 &
while [ ! -e /tmp/.X11-unix/X1 ]; do sleep 0.1; done

if [ "$1" = "getlog" ]; then
  echo "getting log" > export.log
  wine cmd.exe /C wa.exe /getlog /tmp/v/game.WAgame >> export.log 2>&1 &
  rm -f /tmp/v/game.log
  while [ ! -s /tmp/v/game.log ]; do xvkbd -display :1 -text "\r" >> export.log 2>&1; done
  while ! tail -1 /tmp/v/game.log | grep -qE “(Worm of the round: |Most (damage|kills) with one shot: )” /tmp/v/game.log; do
    sleep 0.1
  done
elif [ "$1" = "getmap" ]; then
  echo "getting map" > export.log
  wine cmd.exe /C wa.exe /getmap /tmp/v/game.WAgame >> export.log 2>&1 &
  rm -f User/SavedLevels/game.LEV
  while [ ! -e User/SavedLevels/game.LEV ]; do xvkbd -display :1 -text "\r" >> export.log 2>&1; done
else
  echo "pass either getlog or getmap"
  exit 0;
fi

# just give some time to write the last bytes
sleep 0.2

echo 'done' >> export.log
```

## Modifying


If you want to modify stuff start the container without any executions but just bash access:

```
docker run -it –entrypoint='' –privileged –name to_update zemke/docker-wa bash
```

Then edit the `export` file according to your needs and exit the container. Then commit the changes to a new image

```
docker commit –change='CMD ["getlog"]' –change='ENTRYPOINT ["/root/.wine/drive_c/MicroProse/Worms Armageddon/export"]' to_update zemke/docker-wa
```
