# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.17

# set version label
ARG UNRAR_VERSION=6.2.6
ARG BUILD_DATE
ARG VERSION
ARG SABNZBD_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

# environment settings
ENV HOME="/config" \
PYTHONIOENCODING=utf-8

RUN \
  echo "**** install packages ****" && \
  apk add -U --update --no-cache --virtual=build-dependencies \
    build-base \
    libffi-dev \
    openssl-dev \
    python3-dev && \
  apk add  -U --update --no-cache \
    7zip \
    par2cmdline \
    python3 && \
  echo "**** install unrar from source ****" && \
  mkdir /tmp/unrar && \
  curl -o \
    /tmp/unrar.tar.gz -L \
    "https://www.rarlab.com/rar/unrarsrc-${UNRAR_VERSION}.tar.gz" && \  
  tar xf \
    /tmp/unrar.tar.gz -C \
    /tmp/unrar --strip-components=1 && \
  cd /tmp/unrar && \
  make && \
  install -v -m755 unrar /usr/local/bin && \
  echo "**** install sabnzbd ****" && \  
  if [ -z ${SABNZBD_VERSION+x} ]; then \
    SABNZBD_VERSION=$(curl -s https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest \
      | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  mkdir -p /app/sabnzbd && \
  curl -o \
    /tmp/sabnzbd.tar.gz -L \
    "https://github.com/sabnzbd/sabnzbd/releases/download/${SABNZBD_VERSION}/SABnzbd-${SABNZBD_VERSION}-src.tar.gz" && \
  tar xf \
    /tmp/sabnzbd.tar.gz -C \
    /app/sabnzbd --strip-components=1 && \
  cd /app/sabnzbd && \
  python3 -m ensurepip --upgrade && \
  pip3 install -U --no-cache-dir \
    pip \
    wheel && \
  pip3 install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.17/ \
    apprise \
    pynzb \
    requests && \
  pip3 install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.17/ -r requirements.txt && \
  echo "**** install nzb-notify ****" && \   
  NZBNOTIFY_VERSION=$(curl -s https://api.github.com/repos/caronc/nzb-notify/releases/latest \
    | awk '/tag_name/{print $4;exit}' FS='[""]') && \
  mkdir -p /app/nzbnotify && \
  curl -o \
    /tmp/nzbnotify.tar.gz -L \
    "https://api.github.com/repos/caronc/nzb-notify/tarball/${NZBNOTIFY_VERSION}" && \
  tar xf \
    /tmp/nzbnotify.tar.gz -C \
    /app/nzbnotify --strip-components=1 && \
  cd /app/nzbnotify && \
  pip3 install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.17/ -r requirements.txt && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    $HOME/.cache

# add local files
COPY root/ /

# ports and volumes
EXPOSE 8080

