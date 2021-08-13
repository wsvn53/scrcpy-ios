# Scrcpy-iOS

### About

Scrcpy-iOS.app is a remote control tool for Android Phones based on [https://github.com/Genymobile/scrcpy].

![screenshot](https://github.com/wsvn53/scrcpy-ios/blob/main/screenshots/screenshots.jpg?raw=true)

**Features:**

* Connect remote Android via ssh;
* Hardware Decoding screen frames via VideoToolbox.framework;
* Optimized swipe gestures when remote control with unstable network;
* Support connect to sshd/adb which started in Termux app;

### Usage

#### 1. Setup a ssh server

Before using Scrcpy.app, you need to setup a ssh server which with `android-platform-tools` installed. 

This ssh server will bridge all traffics from your iPhone to your Android devices, so you need to make sure you can connect to this ssh server from your iPhone over the network.

* Use **Mac** as SSH Server: Enable "Remote Login" in **"System Preferences > Sharing"**
* Or use a **Docker Container** as SSH Server: https://hub.docker.com/search?q=sshd&type=image, just select a container with sshd installed, it recommended to choose ubuntu or debian container because it is easier to install adb tools
* Or using any other Computers with ssh enabled

Or, you can also setup your Android phones with sshd/adb installed via Termux by following instructions:

* Install `Termux` on your Android https://f-droid.org/en/packages/com.termux/ ;
* Install `sshd` and `adb` in Termux: `pkg install sshd adb-tools`;
* Create or change password of current Termux user: `passwd`;
* Start `sshd` server with command: `sshd`;
* Enable `Wireless Debug` by execute command on your computer: `adb tcpip 5555`;
* Check device in Termux: `adb devices`;
* Now, You can connect to your Android with ssh port `8022` and `any user`;

#### 2. Connect Android devices

Please make sure `android-platform-tools` is installed:

```sh
adb devices
```

If your computer has USB port enabled, you can just plug your Android devices in and enable Developer mode, more details you can check https://developer.android.com/studio/command-line/adb.html#Enabling.

Or you can connect your Android devices via TCP network, more details you can check https://github.com/Genymobile/scrcpy#connection

#### 3. Scrcpy.app connect with ssh server

Some parameters is required:

* **ssh server**, server to connect
* **ssh port**, ssh port to connect
* **ssh user**, ssh user to login
* **ssh password**, ssh password to login

And then click `Connect`. If you encounter errors, please check the ssh settings or adb and Android phone settings.

### 4. About FULL-SCREEN gesture

From version v1.2, Scrcpy.app now support full-screen indicator gesture:

* Swipe **Once** will trigger Android navigation gesture
* Swipe **Twice** will go back to iOS home screen

##### Note:

After your first swipe, iOS home indicator will become **BLACK**, if you swipe again quickly, it will go back to iOS home screen.

If you want to continue trigger Android navigation gesture, you need to wait the indicator become **GRAY**.

### AppStore

~~AppStore version is under reviewing.~~ Before aproved you can follow the BUILD instructions to run on your iPhone devices.

**Sorry, Scrcpy-iOS.app is not available on the AppStore due to non-compliance with Apple's review policy.**

### Build

#### 1. Build requirements

Scrcpy required ffmpeg/libsdl/libssh and scrcpy-server.jar, all these requirements you can just execute:

```sh
make all
```

Notice, the `libssh` is a framework written by golang, so you need to install golang first.

#### 2. Build and Run

Use Xcode to open Scrcpy.xcodeproj, choose target to Build and Run directly.

### Re-CodeSign

If you dont want to build with Xcode, you can download Scrcpy.ipa from https://github.com/wsvn53/scrcpy-ios/releases, and re-codesign it, or use AltStore to install. 

### Supports

Follow my Twitter: https://twitter.com/wsvn53

Telegram Group: https://t.me/joinchat/I_HBlFpB27RkZTRl

### License 

```
Copyright (C) 2021 wsvn53

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

