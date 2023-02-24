# panacea
Arduino control using PhoenixFramework (Elixir)

## Making Erlang work with WebView

- Download and unpack [wxWidgets V3.0.5](https://github.com/wxWidgets/wxWidgets/releases/download/v3.0.5/wxWidgets-3.0.5.tar.bz2) - The v3.3 and above will not work
```bash
wget https://github.com/wxWidgets/wxWidgets/releases/download/v3.0.5/wxWidgets-3.0.5.tar.bz2
tar -xf <FILENAME>
cd <DIRECTORY>
```
- Compile and install wxWidgets
```bash
./configure --enable-webview
make -j6
sudo make install
sudo ldconfig
```
- Install Erlang (the latest 24.X version available) using `asdf`
```bash
KERL_USE_AUTOCONF=0 KERL_CONFIGURE_OPTIONS="--enable-wx --with-wx --enable-webview --with-wx-config=/usr/local/bin/wx-config" asdf install erlang 24.3.4.9
```
- Install the latest Elixir (for OTP 24)
```bash
asdf install elixir 1.14.3-otp-24
```