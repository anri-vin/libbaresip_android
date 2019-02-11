# -------------------- VALUES TO CONFIGURE --------------------
# Path to your Android NDK
NDK_PATH  := /opt/android-ndk-r19

# Android API level:
API_LEVEL := 28

OUTPUT_DIR := output

# -------------------- GENERATED VALUES --------------------
SHELL = /bin/bash

# Possible values for ANDROID_TARGET_ARCH: [armeabi-v7a, arm64-v8a, x86, x86_64]
ifeq ($(ANDROID_TARGET_ARCH), armeabi-v7a)
	TARGET       := arm-linux-androideabi
	CLANG_TARGET := armv7a-linux-androideabi
	ARCH         := arm
	OPENSSL_ARCH := android-arm
	MARCH        := armv7-a
else ifeq ($(ANDROID_TARGET_ARCH), arm64-v8a)
	TARGET       := aarch64-linux-android
	CLANG_TARGET := $(TARGET)
	ARCH         := arm
	OPENSSL_ARCH := android-arm64
	MARCH        := armv8-a
else ifeq ($(ANDROID_TARGET_ARCH), x86)
	TARGET       := i686-linux-android
	CLANG_TARGET := $(TARGET)
	ARCH	     := i386
	OPENSSL_ARCH := android-x86
	MARCH        := i686
else ifeq ($(ANDROID_TARGET_ARCH), x86_64)
	TARGET       := x86_64-linux-android
	CLANG_TARGET := $(TARGET)
	ARCH         := x86_64
	OPENSSL_ARCH := android-x86_64
	MARCH        := x86-64
endif

PLATFORM	:= android-$(API_LEVEL)
OS		:= $(shell uname -s | tr "[A-Z]" "[a-z]")
HOST_OS		:= linux-x86_64
PWD		:= $(shell pwd)

# Toolchain and sysroot
TOOLCHAIN	:= $(NDK_PATH)/toolchains/llvm/prebuilt/linux-x86_64
SYSROOT		:= $(TOOLCHAIN)/sysroot

# Toolchain tools
PATH	:= $(TOOLCHAIN)/bin:/usr/bin:/bin
AR	:= $(TARGET)-ar
AS	:= $(CLANG_TARGET)$(API_LEVEL)-clang
CC	:= $(CLANG_TARGET)$(API_LEVEL)-clang
CXX	:= $(CLANG_TARGET)$(API_LEVEL)-clang++
LD	:= $(TARGET)-ld
RANLIB	:= $(TARGET)-ranlib
STRIP	:= $(TARGET)-strip

# Compiler and Linker Flags for re, rem, and baresip
#
# NOTE: use -isystem to avoid warnings in system header files
COMMON_CFLAGS := -isystem $(SYSROOT)/usr/include -fPIE -fPIC

CFLAGS := $(COMMON_CFLAGS) \
	-I$(PWD)/openssl/include \
	-I$(PWD)/opus/include_opus \
	-march=$(MARCH)

LFLAGS := -L$(SYSROOT)/usr/lib/ \
	-L$(PWD)/openssl \
	-L$(PWD)/opus/.libs \
	-fPIE -pie

COMMON_FLAGS := \
	EXTRA_CFLAGS="$(CFLAGS) -DANDROID" \
	EXTRA_CXXFLAGS="$(CFLAGS) -DANDROID" \
	EXTRA_LFLAGS="$(LFLAGS)" \
	SYSROOT=$(SYSROOT)/usr \
	HAVE_INTTYPES_H=1 \
	HAVE_GETOPT=1 \
	HAVE_LIBRESOLV= \
	HAVE_RESOLV= \
	HAVE_PTHREAD=1 \
	HAVE_PTHREAD_RWLOCK=1 \
	HAVE_LIBPTHREAD= \
	HAVE_INET_PTON=1 \
	HAVE_INET6=1 \
	HAVE_GETIFADDRS= \
	PEDANTIC= \
	OS=$(OS) \
	ARCH=$(ARCH) \
	USE_OPENSSL=yes \
	USE_OPENSSL_DTLS=yes \
	USE_OPENSSL_SRTP=yes \
	ANDROID=yes \
	RELEASE=1

EXTRA_MODULES := g711 stdio opensles dtls_srtp echo aubridge opus

all: 
	make install ANDROID_TARGET_ARCH=armeabi-v7a
	make install ANDROID_TARGET_ARCH=arm64-v8a
	make install ANDROID_TARGET_ARCH=x86
	make install ANDROID_TARGET_ARCH=x86_64
	make copy-headers

.PHONY: openssl
openssl:
	cd openssl && \
	CC=clang ANDROID_NDK=$(NDK_PATH) PATH=$(PATH) ./Configure $(OPENSSL_ARCH) no-shared $(OPENSSL_FLAGS) && \
	CC=clang ANDROID_NDK=$(NDK_PATH) PATH=$(PATH) make build_libs

.PHONY: opus
opus:
	cd opus && \
	rm -rf include_opus && \
	CC="$(CC) --sysroot $(SYSROOT)" RANLIB=$(RANLIB) AR=$(AR) PATH=$(PATH) ./configure --host=$(TARGET) --disable-shared --disable-doc --disable-extra-programs CFLAGS="$(COMMON_CFLAGS)" && \
	CC="$(CC) --sysroot $(SYSROOT)" RANLIB=$(RANLIB) AR=$(AR) PATH=$(PATH) make && \
	mkdir include_opus && \
	mkdir include_opus/opus && \
	cp include/* include_opus/opus

libre.a:
	@rm -f re/libre.*
	PATH=$(PATH) RANLIB=$(RANLIB) AR=$(AR) CC=$(CC) make $@ -C re $(COMMON_FLAGS)

librem.a: libre.a
	@rm -f rem/librem.*
	PATH=$(PATH) RANLIB=$(RANLIB) AR=$(AR) CC=$(CC) make $@ -C rem $(COMMON_FLAGS)

libbaresip: openssl opus librem.a libre.a
	@rm -f baresip/baresip baresip/src/static.c
	PKG_CONFIG_LIBDIR="$(SYSROOT)/usr/lib/pkgconfig" PATH=$(PATH) RANLIB=$(RANLIB) AR=$(AR) CC=$(CC) \
	make libbaresip.a -C baresip $(COMMON_FLAGS) STATIC=1 LIBRE_SO=$(PWD)/re LIBREM_PATH=$(PWD)/rem MOD_AUTODETECT= EXTRA_MODULES="$(EXTRA_MODULES)"

ifdef ANDROID_TARGET_ARCH

ifneq ($(shell [[ $(ANDROID_TARGET_ARCH) == armeabi-v7a || $(ANDROID_TARGET_ARCH) == arm64-v8a || $(ANDROID_TARGET_ARCH) == x86 || $(ANDROID_TARGET_ARCH) == x86_64 ]] && echo true) , true)
$(error Unknown ANDROID_TARGET_ARCH passed to makefile: $(ANDROID_TARGET_ARCH))
endif

install: libbaresip
	rm -rf $(OUTPUT_DIR)/$(ANDROID_TARGET_ARCH)
	mkdir -p $(OUTPUT_DIR)/$(ANDROID_TARGET_ARCH)
	cp openssl/libcrypto.a $(OUTPUT_DIR)/$(ANDROID_TARGET_ARCH)
	cp openssl/libssl.a $(OUTPUT_DIR)/$(ANDROID_TARGET_ARCH)
	cp opus/.libs/libopus.a $(OUTPUT_DIR)/$(ANDROID_TARGET_ARCH)
	cp re/libre.a $(OUTPUT_DIR)/$(ANDROID_TARGET_ARCH)
	cp rem/librem.a $(OUTPUT_DIR)/$(ANDROID_TARGET_ARCH)
	cp baresip/libbaresip.a $(OUTPUT_DIR)/$(ANDROID_TARGET_ARCH)
else

install:
	$(error ANDROID_TARGET_ARCH is not set)

endif

.PHONY: copy-headers
copy-headers:
	rm -rf $(OUTPUT_DIR)/include
	mkdir -p $(OUTPUT_DIR)/include/re
	cp re/include/* $(OUTPUT_DIR)/include/re
	mkdir $(OUTPUT_DIR)/include/rem
	cp rem/include/* $(OUTPUT_DIR)/include/rem
	cp baresip/include/baresip.h $(OUTPUT_DIR)/include

.PHONY: download-sources
download-sources:
	rm -rf baresip re rem openssl opus
	git clone https://github.com/alfredh/baresip.git
	git clone https://github.com/creytiv/rem.git
	git clone https://github.com/creytiv/re.git
	git clone https://github.com/openssl/openssl.git
	wget http://downloads.xiph.org/releases/opus/opus-1.1.3.tar.gz
	tar zxf opus-1.1.3.tar.gz
	rm opus-1.1.3.tar.gz
	mv opus-1.1.3 opus
