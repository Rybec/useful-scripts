# Get necessary packages
sudo apt-get install openjdk-8-jdk ant android-sdk-platform-tools-common make

# Make Android directory, for doing all this stuff
cd ~
mkdir Android
cd Android

# Download SDK and NDK
wget https://dl.google.com/android/repository/tools_r25.2.5-linux.zip &
wget https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip &
wait

# Install Android SDK 25.2.5 (do not update this version)
unzip tools_r25.2.5-linux.zip
rm tools_r25.2.5-linux.zip

# Install latest NDK (you can update this version if you want, but you also have to update it in other places in this file)
unzip android-ndk-r16b-linux-x86_64.zip
rm android-ndk-r16b-linux-x86_64.zip

# Install components (you can change versions, if you need to)
tools/bin/sdkmanager "build-tools;27.0.3"
tools/bin/sdkmanager "platform-tools"
tools/bin/sdkmanager "platforms;android-21"

# Add stuff to the path
echo >> ~/.bashrc
echo PATH=\"$HOME/Android/android-ndk-r16b:\$PATH\" >> ~/.bashrc
echo PATH=\"$HOME/Android/tools:\$PATH\" >> ~/.bashrc
echo PATH=\"$HOME/Android/platform-tools:\$PATH\" >> ~/.bashrc

# Load the new .bashrc entries into the current context
source ~/.bashrc

# Install SDL2
mkdir SDL2
cd SDL2
wget https://libsdl.org/release/SDL2-2.0.7.tar.gz
wget https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.2.tar.gz
wget https://hg.libsdl.org/SDL_mixer/archive/5fe3b562f4e2.tar.gz
wget https://www.libsdl.org/projects/SDL_net/release/SDL2_net-2.0.1.tar.gz
wget https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.14.tar.gz

tar xf SDL2-2.0.7.tar.gz
tar xf SDL2_image-2.0.2.tar.gz
tar xf 5fe3b562f4e2.tar.gz
tar xf SDL2_net-2.0.1.tar.gz
tar xf SDL2_ttf-2.0.14.tar.gz

rm *.tar.gz

ln -s SDL2-2.0.7 SDL2
ln -s SDL2_image-2.0.2 SDL2_image
ln -s SDL_mixer-5fe3b562f4e2 SDL2_mixer
ln -s SDL2_net-2.0.1 SDL2_net
ln -s SDL2_ttf-2.0.14 SDL2_ttf

# Build shared libraries
sed -i 's/SUPPORT_WEBP ?= true/SUPPORT_WEBP ?= false/g' SDL2_image/Android.mk
sed -i '/IMG_WIC\.c/d' SDL2_image/Android.mk
cd SDL2/build-scripts
sed -i '/$ANDROID update project --path/ s/$/ --target android-21/' androidbuild.sh
./androidbuild.sh org.libsdl /dev/null
cd ../build/org.libsdl
rm -rf jni/src/

ln -s $HOME/Android/SDL2/SDL2_image jni/
# ln -s $HOME/Android/SDL2/SDL2_image/external/libwebp-0.6.0 jni/webp
ln -s $HOME/Android/SDL2/SDL2_mixer jni/
ln -s $HOME/Android/SDL2/SDL2_mixer/external/libmikmod-3.1.12 jni/libmikmod
ln -s $HOME/Android/SDL2/SDL2_mixer/external/smpeg2-2.0.0 jni/smpeg2
ln -s $HOME/Android/SDL2/SDL2_net jni/
ln -s $HOME/Android/SDL2/SDL2_ttf jni/

ndk-build -j$(nproc)

# Install SDL2 into x86 and ARM toolchains
~/Android/android-ndk-r16b/build/tools/make-standalone-toolchain.sh --platform=android-14 --install-dir=$HOME/Android/ndk-standalone-14-arm --arch=arm
~/Android/android-ndk-r16b/build/tools/make-standalone-toolchain.sh --platform=android-14 --install-dir=$HOME/Android/ndk-standalone-14-x86 --arch=x86

NDK_ARM=$HOME/Android/ndk-standalone-14-arm
NDK_x86=$HOME/Android/ndk-standalone-14-x86

cd ~/Android/SDL2/SDL2/build/org.libsdl
for i in libs/armeabi/*; do ln -nfs $(pwd)/$i $NDK_ARM/sysroot/usr/lib/; done
for i in libs/x86/*; do ln -nfs $(pwd)/$i $NDK_x86/sysroot/usr/lib/; done

mkdir $NDK_ARM/sysroot/usr/include/SDL2/
mkdir $NDK_x86/sysroot/usr/include/SDL2/

cp jni/SDL/include/* $NDK_ARM/sysroot/usr/include/SDL2/
cp jni/*/SDL*.h $NDK_ARM/sysroot/usr/include/SDL2/
cp jni/SDL/include/* $NDK_x86/sysroot/usr/include/SDL2/
cp jni/*/SDL*.h $NDK_x86/sysroot/usr/include/SDL2/


# Install OpenSSL (for HTTPS support)

cd $HOME/Android
mkdir openssl
cd openssl
wget https://www.openssl.org/source/openssl-1.0.2g.tar.gz
tar xzf openssl-1.0.2g.tar.gz
rm openssl-1.0.2g.tar.gz

wget https://raw.githubusercontent.com/Rybec/pjsip-android-builder/master/openssl-build
chmod +x openssl-build

./openssl-build $HOME/Android/android-ndk-r16b/ ./openssl-1.0.2g 21 armeabi 4.9 ~/Android/openssl/arm/
./openssl-build $HOME/Android/android-ndk-r16b/ ./openssl-1.0.2g 21 x86 4.9 ~/Android/openssl/x86/

cp arm/lib/* $NDK_ARM/sysroot/usr/lib/ -r
cp x86/lib/* $NDK_x86/sysroot/usr/lib/ -r

cp arm/include/openssl $NDK_ARM/sysroot/usr/include/ -r
cp x86/include/openssl $NDK_x86/sysroot/usr/include/ -r


# Create project template

# Create Projects Directory
cd ~/Android
mkdir projects
cd projects

cp ~/Android/SDL2/SDL2/android-project ./template -r
cd template

cp ~/Android/SDL2/SDL2/build/org.libsdl/libs ./ -r

cp ~/Android/openssl/arm/lib/libssl.so ./libs/armeabi/
cp ~/Android/openssl/arm/lib/libcrypto.so ./libs/armeabi/
cp ~/Android/openssl/x86/lib/libssl.so ./libs/x86/
cp ~/Android/openssl/x86/lib/libcrypto.so ./libs/x86/


## Tell Java to load these
sed -i '/\/\/ "SDL2_ttf",/ a\            "ssl",\n            "crypto",' src/org/libsdl/app/SDLActivity.java


# Time to create a basic Makefile!
echo > Makefile
echo "NAME = appname" >> Makefile
echo "API = android-21" >> Makefile
echo >> Makefile
echo "PATH_x86 = \"\$(HOME)/Android/ndk-standalone-14-x86/bin:\$(PATH)\"" >> Makefile
echo "PATH_arm = \"\$(HOME)/Android/ndk-standalone-14-arm/bin:\$(PATH)\"" >> Makefile
echo >> Makefile
echo "CC_x86 = i686-linux-android-gcc" >> Makefile
echo "CC_arm = arm-linux-androideabi-gcc" >> Makefile
echo >> Makefile
echo "CFLAGS = -shared -fPIC" >> Makefile
echo "CFLAGS_x86 = \$(CFLAGS)" >> Makefile
echo "CFLAGS_arm = \$(CFLAGS)" >> Makefile
echo >> Makefile
echo "INCLUDES =" >> Makefile
echo "LIBS = -lSDL2 -lSDL2_image" >> Makefile
echo >> Makefile
echo "OUTPUT_x86 = libs/x86/libmain.so" >> Makefile
echo "OUTPUT_arm = libs/armeabi/libmain.so" >> Makefile
echo >> Makefile
echo "OBJS = main.c" >> Makefile
echo >> Makefile
echo "all: main.c" >> Makefile
echo "	PATH=\$(PATH_x86); \$(CC_x86) \$(OBJS) -o \$(OUTPUT_x86) \$(CFLAGS_x86) \$(INCLUDES) \$(LIBS)" >> Makefile
echo "	PATH=\$(PATH_arm); \$(CC_arm) \$(OBJS) -o \$(OUTPUT_arm) \$(CFLAGS_arm) \$(INCLUDES) \$(LIBS)" >> Makefile
echo "	android update project --name \$(NAME) --path . --target \$(API)" >> Makefile
echo "	ant debug" >> Makefile
echo >> Makefile
echo "install:" >> Makefile
echo "	ant installd" >> Makefile
echo >> Makefile
echo "clean:" >> Makefile
echo "	rm libs/x86/libmain.so libs/armeabi/libmain.so" >> Makefile
echo "	ant clean" >> Makefile

touch main.c
mkdir assets
