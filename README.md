# panacea
Arduino control using PhoenixFramework (Elixir)

## Setup steps (Linux)

- Install the dependencies

``` shell
sudo apt-get -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk libgtk-3-dev libwebkit2gtk-4.0-dev
```

- Download and unpack [wxWidgets V3.0.5](https://github.com/wxWidgets/wxWidgets/releases/download/v3.0.5/wxWidgets-3.0.5.tar.bz2) - The v3.3 and above will not work
``` shell
wget https://github.com/wxWidgets/wxWidgets/releases/download/v3.0.5/wxWidgets-3.0.5.tar.bz2
tar -xf <FILENAME>
cd <DIRECTORY>
```
- Compile and install wxWidgets
``` shell
./configure --enable-webview --with-gtk=3
make -j6
sudo make install
sudo ldconfig
```
- Install Erlang (the latest 24.X version available) using `asdf`
``` shell
KERL_USE_AUTOCONF=0 KERL_CONFIGURE_OPTIONS="--enable-wx --with-wx --enable-webview --with-wx-config=/usr/local/bin/wx-config" asdf install erlang 24.3.4.9
```
- Install the latest Elixir (for OTP 24)
``` shell
asdf install elixir 1.14.3-otp-24
```

## Setup steps (Windows)

- Install wxWidgets 3.0.5 (Windows version): https://github.com/wxWidgets/wxWidgets/releases/download/v3.0.5/wxMSW-3.0.5-Setup.exe
- Install Erlang and Elixir: https://github.com/elixir-lang/elixir-windows-setup/releases/download/v2.4/elixir-websetup.exe
- Install chocolatey: https://chocolatey.org/install
- Install mingw through chocolatey (running through an administrator command line):
``` shell
choco install mingw 
```
- Relogin for the changes on the PATH variable to take an effect