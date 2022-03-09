FROM python:3.9-slim-bullseye

ARG PIKEPDF_VERSION="v5.0.1"
ARG DEBIAN_FRONTEND=noninteractive
ARG QPDF_VERSION="release-qpdf-10.6.2"
ARG BUILD_PACKAGES="\
  automake \
  autotools-dev \
  build-essential \
  git \
  # for Numpy
  libjpeg62-turbo-dev \
  libpq-dev \
  python3-dev \
  python3-pip \
  zlib1g-dev"

ARG RUNTIME_PACKAGES="\
  curl \
  gosu \
  libxml2 \
  python3 \
  python3-setuptools \
  tzdata \
  zlib1g"

# Binary dependencies
RUN apt-get update \
  && apt-get -y --no-install-recommends install $BUILD_PACKAGES \
  && apt-get -y --no-install-recommends install $RUNTIME_PACKAGES 

WORKDIR /usr/src/

# Python dependencies and library dependencies
RUN echo "Building qpdf" \
  && mkdir -p /usr/src/qpdf \
  && cd /usr/src/qpdf \
  && git clone https://github.com/qpdf/qpdf.git . \
  && git checkout --quiet ${QPDF_VERSION} \
  && ./configure \
  && make \
  && make install \
  && cd /usr/src \
  && rm -rf /usr/src/qpdf \
  && python3 -m pip install --upgrade pip wheel 

RUN echo "building pikepdf wheel" \
  && git clone https://github.com/pikepdf/pikepdf.git \
  && cd pikepdf \
  && mkdir wheels \
  && git checkout --quiet $PIKEPDF_VERSION \
  && pip wheel . -w wheels \
  && ls -la wheels \
  && apt-get -y --autoremove purge $BUILD_PACKAGES \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/* \
  && rm -rf /var/tmp/* \
  && rm -rf /var/cache/apt/archives/* \
  && truncate -s 0 /var/log/*log
