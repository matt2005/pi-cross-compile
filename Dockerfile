FROM ubuntu:20.04

LABEL org.opencontainers.image.authors="matthilton2005@gmail.com"

# USAGE: docker run -it -v ~/raspberry/hello:/build mitchallen/pi-cross-compile

LABEL com.mitchallen.pi-cross-compile="{\"Description\":\"Cross Compile for Raspberry Pi\",\"Usage\":\"docker run -it -v ~/myprojects/mybuild:/build mitchallen/pi-cross-compile\",\"Version\":\"0.1.0\"}"

# export FREETYPE_VER=2.10.0
# export ZLIB_VER=1.2.11
# export PNG_VER=1.6.37
# export GOLANG_VER=1.13.4
# export HOST=arm-linux-gnueabihf
# export CFLAGS=-I/usr/arm-linux-gnueabihf/include 
# export LDFLAGS=-L/usr/arm-linux-gnueabihf/lib
# export CPPFLAGS=-I/usr/arm-linux-gnueabihf/include
# export CC=/pitools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-gcc
# export CXX=/pitools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-g++
# export PREFIX=/usr/${HOST}

ENV DEBIAN_FRONTEND noninteractive
ARG DEBIAN_FRONTEND=noninteractive
ENV FREETYPE_VER 2.10.0
ENV ZLIB_VER 1.2.11
ENV PNG_VER 1.6.37
ENV GOLANG_VER 1.13.4
ENV HOST arm-linux-gnueabihf

RUN apt-get update && apt-get install -y git build-essential cmake pkg-config wget gcc-multilib

RUN git clone --progress --verbose https://github.com/raspberrypi/tools.git --depth=1 pitools
RUN git clone --progress --verbose https://github.com/raspberrypi/userland.git --depth=1 userland

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/pitools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin

RUN cd /userland && ./buildme && cd build/arm-linux/release && make install
RUN mkdir -p /opt/vc/src && \
    cd /userland/host_applications/linux/apps && \
    cp -R * /opt/vc/src/ && \
    mkdir -p /usr/${HOST}/lib && \
    mkdir -p /usr/${HOST}/include

ENV CC /pitools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-gcc
ENV CXX /pitools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-g++
ENV PREFIX /usr/${HOST}
ENV CPPFLAGS -I/usr/arm-linux-gnueabihf/include
ENV CFLAGS -I/usr/arm-linux-gnueabihf/include
ENV LDFLAGS -L/usr/arm-linux-gnueabihf/lib -Wl,-rpath /usr/arm-linux-gnueabihf/lib -Wl,-rpath /opt/vc/lib/

# install arm libz
RUN cd /tmp && \
    wget -q --no-check-certificate "https://www.zlib.net/zlib-${ZLIB_VER}.tar.gz" && \
    tar xzf zlib-${ZLIB_VER}.tar.gz && \
    cd /tmp/zlib-${ZLIB_VER} && \
    ./configure --prefix=${PREFIX} && \
    make install && \
    cd /tmp && \
    rm -rf zlib-${ZLIB_VER}.tar.gz zlib-${ZLIB_VER}/

# install arm libpng
RUN cd /tmp && \
    wget -q --no-check-certificate "https://download.sourceforge.net/libpng/libpng-${PNG_VER}.tar.gz" && \
    tar xzf libpng-${PNG_VER}.tar.gz && \
    cd libpng-${PNG_VER} && \
    ./configure --host=${HOST} --prefix=${PREFIX} && \
    make && \
    make install && \
    cd /tmp && \
    rm -rf libpng-${PNG_VER}.tar.gz libpng-${PNG_VER}/

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/pitools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin:${PREFIX}/bin
ENV ZLIB_LIBS /usr/arm-linux-gnueabihf/lib/libz.a

# install freetype
RUN cd /tmp && \
    wget -q --no-check-certificate "https://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VER}.tar.bz2" && \
    tar xjf freetype-${FREETYPE_VER}.tar.bz2 && \
    cd /tmp/freetype-${FREETYPE_VER} && \
    ./configure --host=${HOST} --prefix=${PREFIX} --with-png=yes && \
    make install && \
    cd /tmp && \
    rm -rf freetype-${FREETYPE_VER}.tar.bz2 freetype-${FREETYPE_VER}/

# export CFLAGS="-I/usr/arm-linux-gnueabihf/include -I/usr/arm-linux-gnueabihf/include/freetype2"

ENV CFLAGS -I/usr/arm-linux-gnueabihf/include -I/usr/arm-linux-gnueabihf/include/freetype2

# make everything except fft
RUN cd /opt/vc/src/hello_pi/ && \
    make -C libs/ilclient clean && \
    make -C libs/vgfont clean && \
    make -C libs/revision clean && \
    make -C hello_world clean && \
    make -C hello_triangle clean && \
    make -C hello_triangle2 clean && \
    make -C hello_video clean && \
    make -C hello_audio clean && \
    make -C hello_font clean && \
    make -C hello_dispmanx clean && \
    make -C hello_tiger clean && \
    make -C hello_encode clean && \
    make -C hello_jpeg clean && \
    make -C hello_videocube clean && \
    make -C hello_teapot clean && \
    make -C hello_mmal_encode clean && \
    make -C libs/ilclient && \
    make -C libs/vgfont && \
    make -C libs/revision && \
    make -C hello_world && \
    make -C hello_triangle && \
    make -C hello_triangle2 && \
    make -C hello_video && \
    make -C hello_audio && \
    make -C hello_font && \
    make -C hello_dispmanx && \
    make -C hello_tiger && \
    make -C hello_encode && \
    make -C hello_jpeg && \
    make -C hello_videocube && \
    make -C hello_teapot && \
    make -C hello_mmal_encode

# install golang for host
RUN cd /tmp &&  \
    wget -q https://dl.google.com/go/go${GOLANG_VER}.linux-amd64.tar.gz && \
    tar xzf go${GOLANG_VER}.linux-amd64.tar.gz -C /usr/local && \
    rm go${GOLANG_VER}.linux-amd64.tar.gz

ENV BUILD_FOLDER /build
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/pitools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin:/usr/local/go/bin

WORKDIR ${BUILD_FOLDER}

CMD ["/bin/bash", "-c", "make", "-f", "${BUILD_FOLDER}/Makefile"]
# CMD ["make", "clean"]
