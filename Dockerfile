FROM ubuntu:20.04 AS builder

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  wget \
  p7zip-full \
  unshield

COPY wa.iso .

# CD contents
RUN mkdir -p wa/cd \
  && cd wa/cd \
  && 7z x ../../wa.iso

# Game installation directory
RUN mkdir wa/cab \
  && cd wa/cab \
  && unshield x ../cd/Install/data1.cab

# Merge and fix case
RUN mv wa/cab/Program_Executable_Files wa/game \
  && cp -lnTR wa/cd/Data wa/game/DATA \
  && bash -c 'mv wa/game/User/{g,G}raves' \
  && bash -c 'mv wa/game/{g,G}raphics' \
  && bash -c 'mv wa/game/Graphics/{optionsmenu,OptionsMenu}'

RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key -O /tmp/winehq.key

# Updates
COPY wa_3_8_1_cd_update.exe wa/game

# Installing the updates
RUN cd wa/game \
  && 7z x -aoa wa_3_8_1_cd_update.exe \
  && rm -rf \$PLUGINSDIR \
  && bash -c "printf '\x02' | dd of='WA.exe' bs=1 seek=2717442 count=1 conv=notrunc" \
  && bash -c "printf '\xF2' | dd of='WA.exe' bs=1 seek=360 count=1 conv=notrunc"

# Remove files unnecessary for non-interactive (headless) use
# RUN cd wa/game \
#   && find -regextype egrep -not -regex '^\.(|/(WA\.exe|ltfil10N\.DLL|ltkrn10N\.dll|lflmb10N\.dll|DATA(|/ImgHoles.*|/User(|/Languages(|/[0-9][^/]*(|/English.txt)))|/Mission.*|/Level.*|/Image.*|/Gfx(|/Gfx\.dir|/Water\.dir)|/Custom.*)))$' \
#     -printf 'Deleting %p\n' -delete


FROM ubuntu:20.04

# Get key to Wine repo
COPY --from=builder /tmp/winehq.key /tmp/winehq.key

# Add Wine repo
RUN apt-get update \
  && apt-get install -y software-properties-common gnupg \
  && apt-key add /tmp/winehq.key \
  && add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main' \
  && rm /tmp/winehq.key

# AMD 32-bit deps for Wine
RUN dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install -y --install-recommends winehq-stable wine32 xvfb \
  && rm -rf /var/lib/apt/lists/*

# Create WINEPREFIX
RUN WINEDLLOVERRIDES="mscoree,mshtml=" xvfb-run wineboot -i \
  && wineserver -k

# Copy game installation directory
COPY --from=builder wa/game /root/.wine/drive_c/WA

# Some settings for WA
RUN wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v WineCompatibilitySuggested /d 0x7FFFFFFF /f \
  && wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v WindowedMode /d 0x00000001 /f \
  && wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v ChatPinned /d 0x00000001 /f \
  && wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v DetailLevel /d 0x00000005 /f \
  && wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v WindowedMode /d 0x00000001 /f \
  && wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v PinnedChatLines /d 0x00000007 /f \
  && wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v InfoTransparency /d 0x00000001 /f \
  && wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v InfoSpy /d 0x00000001 /f \
  && wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v DisableSmoothBackgroundGradient /d 0x00000000 /f \
  && wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v HardwareRendering /d 0x00000001 /f \
  && wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v LargerFonts /d 0x00000000 /f \
  && wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v AssistedVsync /d 0x00000000 /f \
  && wine reg add 'HKEY_CURRENT_USER\Software\Team17SoftwareLTD\WormsArmageddon\Options' /t REG_DWORD /v Vsync /d 0x00000000 /f \
  && wineserver -k

# Add scripts
COPY scripts/* /usr/local/bin/

