FROM ghcr.io/schnuffle/build-pikepdfwheel-backport-arm-base-qpdf:latest

ARG PIKEPDF_VERSION="v5.0.1"
ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_PACKAGES="\
  build-essential \
  git \
  libtool \
  libjpeg62-turbo-dev \
  libpq-dev \
  python3-dev \
  python3-pip \
  libxml2-dev \
  libxslt1-dev \
  libleptonica-dev \
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
  && apt-get -y upgrade \ 
  && apt-get -y --no-install-recommends install $BUILD_PACKAGES $RUNTIME_PACKAGES \
  && apt-get -y --no-install-recommends install $(ls /usr/src/qpdf/libqpdf-dev*.deb) \
  && dpkg -l | grep qpdf

WORKDIR /usr/src/

RUN echo "building/installing pikepdf wheel" \
  && python3 -m pip install --upgrade pip wheel \
  && git clone https://github.com/pikepdf/pikepdf.git \
  && cd pikepdf \
  && mkdir wheels \
  && git checkout --quiet $PIKEPDF_VERSION \
  && python3 -m pip wheel . -w wheels \
  && ls -la wheels \
  && python3 -m pip install wheels/*.whl \
  && python3 -m pip freeze

WORKDIR /usr/src/
RUN echo "Building/installing psycopg2 wheel" \
  && git clone https://github.com/psycopg/psycopg2.git \
  && cd psycopg2 \
  && mkdir wheels \
  && python3 -m pip wheel . -w wheels \
  && ls -la wheels \
  && python3 -m pip install wheels/*.whl \
  && python3 -m pip freeze
  
RUN echo "building jbig2enc" \
  && mkdir /usr/src/jbig2enc \
  && cd /usr/src/jbig2enc \
  && git clone --quiet https://github.com/agl/jbig2enc . \
  && ./autogen.sh \
  && ./configure && make \
  && ls -la /usr/src/jbig2enc \
  && apt-get -y --autoremove purge $BUILD_PACKAGES \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/* \
  && rm -rf /var/tmp/* \
  && rm -rf /var/cache/apt/archives/* \
  && truncate -s 0 /var/log/*log
