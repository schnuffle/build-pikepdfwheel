FROM python:3.9-slim

ARG PIKEPDF_VERSION="v5.0.1"
ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_PACKAGES="\
  build-essential \
  gcc \
  debhelper \
  debian-keyring \
  devscripts \
  equivs  \
  git \
  libtool \
  libjpeg62-turbo-dev \
  libleptonica-dev \
  libpq-dev \
  libmagic-dev \
  libxml2-dev \
  libxslt1-dev \
  libjpeg-dev \
  libgnutls28-dev \
  # for Numpy
  libatlas-base-dev \
  libxslt1-dev \
  python3-dev \
  python3-pip \
  packaging-dev \ 
  tzdata \
  zlib1g-dev"


ARG RUNTIME_PACKAGES="\
  curl \
  file \
  # fonts for text file thumbnail generation
  fonts-liberation \
  gettext \
  ghostscript \
  gnupg \
  gosu \
  icc-profiles-free \
  imagemagick \
  media-types \
  liblept5 \
  libxml2 \
  optipng \
  python3 \
  python3-setuptools \
  # thumbnail size reduction
  pngquant \
  # OCRmyPDF dependencies
  tesseract-ocr \
  tesseract-ocr-eng \
  tesseract-ocr-deu \
  tesseract-ocr-fra \
  tesseract-ocr-ita \
  tesseract-ocr-spa \
  tzdata \
  unpaper \
  # Mime type detection
  zlib1g"
  
WORKDIR /usr/src

# Backporting qpdf from debian testing on arm
RUN if [ "$(uname -m)" = "armv7l" ] || [ "$(uname -m)" = "aarch64" ]; \
    then \
    echo "deb-src http://deb.debian.org/debian/ bookworm main" > /etc/apt/sources.list.d/bookworm-src.list \
    && apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends $BUILD_PACKAGES $RUNTIME_PACKAGES \
    && mkdir qpdf \
    && cd qpdf \
    && apt source libqpdf28/testing \
    && cd qpdf-10.6.2 \
    && DEBEMAIL=me@schnuffle.de dch --bpo \
    && dpkg-buildpackage -b -us -uc \
    && apt install -y --no-install-recommends $(ls ../libqpdf28_*.deb) \
    && apt install -y --no-install-recommends $(ls ../libqpdf-dev_*.deb) \
    && apt install -y --no-install-recommends $(ls ../qpdf_*.deb) \
    && dpkg -l | grep qpdf; \
  else \
    echo "Skipping qpdf build because pikepdf binary wheels are available." \
    && apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends libqpdf28 qpdf; \
  fi

# build/install pikepdf on arm
RUN if [ "$(uname -m)" = "armv7l" ] || [ "$(uname -m)" = "aarch64" ]; \
    then \
    echo "building/installing pikepdf wheel" \
    && python3 -m pip install --upgrade pip wheel \
    && cd /usr/src \
    && git clone https://github.com/pikepdf/pikepdf.git \
    && cd pikepdf \
    && mkdir wheels \
    && git checkout --quiet $PIKEPDF_VERSION \
    && python3 -m pip wheel . -w wheels \
    && ls -la wheels \
    && python3 -m pip install wheels/*.whl \
    && python3 -m pip freeze; \
  else \
    echo "No need to compile wheel"; \
  fi

# build install psycopg2
RUN if [ "$(uname -m)" = "armv7l" ] || [ "$(uname -m)" = "aarch64" ]; \
  then \
    echo "Building/installing psycopg2 wheel" \
    && cd /usr/src \
    && git clone https://github.com/psycopg/psycopg2.git \
    && cd psycopg2 \
    && mkdir wheels \
    && python3 -m pip wheel . -w wheels \
    && ls -la wheels \
    && python3 -m pip install wheels/*.whl \
    && python3 -m pip freeze; \
  else \
    echo "No need to compile psycopg2"; \
  fi

# install python deps
COPY requirements.txt .
RUN echo "building/installing python requirements" \
  && python3 -m pip install -r requirements.txt

# build install jibig2enc
RUN echo "building jbig2enc" \
  && mkdir /usr/src/jbig2enc \
  && cd /usr/src/jbig2enc \
  && git clone --quiet https://github.com/agl/jbig2enc . \
  && ./autogen.sh \
  && ./configure && make \
  && ls -la /usr/src/jbig2enc

RUN echo "Cleanup image" \
  && apt-get -y --autoremove purge $BUILD_PACKAGES \
  && apt-get clean \
  && if [ "$(uname -m)" = "armv7l" ] || [ "$(uname -m)" = "aarch64" ]; \
    then \
    rm -rf /usr/src/psycopg2 \
    && rm -rf /usr/src/pikepdf \
    && rm -rf /usr/src/qpdf; \
  fi \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/* \
  && rm -rf /var/tmp/* \
  && rm -rf /var/cache/apt/archives/* \
  && truncate -s 0 /var/log/*log
