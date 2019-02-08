libbaresip-android
==================

This project shows how to build libbaresip for Android using Android NDK
r19. Resulting libbaresip can be used in Baresip based Android applications.

Currently supported NDKs:

| NDK  | Supported  |
|------|------------|
| r19  | Yes        |
| r18  | No         |
| ...  | No         |

## Step 0 - download Android NDK

Download and unzip Android NDK for Linux from:
```
https://developer.android.com/ndk/downloads/
```
or use ndk-bundle that comes with Andoid SDK.

## Step 1 - clone libbaresip-android

Clone libbaresip-android repository:
```
$ git clone https://github.com/anri-vin/libbaresip_android.git
```
This will create libbaresip-android directory containing Makefile.  

## Step 2 - edit Makefile

Go to ./libbaresip-android directory and edit Makefile.
You need to set (or check) following variables:

NDK_PATH  - Path to your NDK bundle. E.g. /opt/android-ndk-r19
API_LEVEL - Target android API level. E.g. 28
OUTPUT_DIR - Directory where output shoud be stored. E.g. output or /home/user/output

## Step 3 - download sources

Downloading all required sources is easy:

```
$ make download-sources
```

After that you should have in libbaresip-android directory a layout like
this:

```
    baresip/
    openssl/
    opus/
    re/
    rem/
```

## Step 4 - build libbaresip
You can build library only for selected architecture.
Replace $ARCH with one of following: armeabi-v7a, arm64-v8a, x86 or x86_64:

```
$ make install ANDROID_TARGET_ARCH=$ARCH
$ make copy-headers
```

Or you can build everything in one command:

```
$ make all
```

After that you will have all required libraries in the output folder.
