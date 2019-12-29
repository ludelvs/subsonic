FROM ubuntu:18.04

ENV SUBSONIC_VERSION 6.1.6
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root
ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig
ENV PATH $HOME/bin:$PATH
#ENV LC_ALL=ja_JP.UTF-8

RUN apt -qq update && \
    apt -y install \
    autoconf automake \
    locales language-pack-ja tzdata lame git \
    software-properties-common  lib32stdc++6 \
    pkg-config cmake libass-dev libfreetype6-dev \
    libtheora-dev \
    libtool \
    libva-dev \
    libvdpau-dev \
    libvorbis-dev \
    libxcb1-dev \
    libxcb-shm0-dev \
    libxcb-xfixes0-dev \
    mercurial \
    pkg-config \
    texinfo \
    wget \
    zlib1g-dev \
    libfdk-aac-dev \
    yasm build-essential libtool libmp3lame-dev wget \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN locale-gen ja_JP.UTF-8 && dpkg-reconfigure locales && \
    echo "Asia/Tokyo" > /etc/timezone && dpkg-reconfigure tzdata

RUN mkdir ~/ffmpeg_sources

RUN cd ~/ffmpeg_sources && \
  wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
  tar xjf ffmpeg-snapshot.tar.bz2 && \
  rm ffmpeg-snapshot.tar.bz2 && \
  cd ffmpeg && \
   ./configure \
    --prefix="$HOME/ffmpeg_build" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$HOME/ffmpeg_build/include" \
    --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
    --extra-libs="-lpthread -lm" \
    --bindir="$HOME/bin" \
    --enable-gpl \
    --enable-libfdk-aac \
    --enable-libmp3lame \
    --enable-nonfree && \
  make && \
  make install && \
  make distclean && \
  hash -r

RUN add-apt-repository ppa:linuxuprising/java \
    && apt update \
    && apt -y install openjdk-8-jdk \
    && apt update \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cd /tmp && \
    wget "https://s3-eu-west-1.amazonaws.com/subsonic-public/download/subsonic-${SUBSONIC_VERSION}.deb" && \
    dpkg -i /tmp/subsonic-${SUBSONIC_VERSION}.deb && rm -f /tmp/*.deb

EXPOSE 4040

CMD export LANG=ja_JP.UTF-8 && \
  rm -rf /subsonic/transcode/ffmpeg && \
  rm -rf /subsonic/transcode/lame && \
  ln -s /usr/local/bin/ffmpeg /subsonic/transcode/ffmpeg && \
  ln -s /usr/bin/lame /subsonic/transcode/lame && \
  /usr/bin/subsonic \
  --home=/subsonic \
  --host=0.0.0.0 \
  --port=4040 \
  --max-memory=100 \
  --default-music-folder=/music \
  --default-podcast-folder=/podcast \
  --default-playlist-folder=/playlist \
  && sleep 1 && tail -f /subsonic/subsonic_sh.log
