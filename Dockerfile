
#bench Dockerfile

FROM ubuntu:16.04
LABEL MAINTAINER frappé

USER root
# Generate locale C.UTF-8 for mariadb and general locale data
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y iputils-ping git build-essential python-setuptools python-dev libffi-dev libssl-dev libjpeg8-dev \
  redis-tools redis-server software-properties-common libxrender1 libxext6 xfonts-75dpi xfonts-base zlib1g-dev libfreetype6-dev \
  liblcms2-dev libwebp-dev python-tk apt-transport-https libsasl2-dev libldap2-dev libtiff5-dev tcl8.6-dev tk8.6-dev \
  wget libmysqlclient-dev mariadb-client mariadb-common curl rlwrap redis-tools nano wkhtmltopdf python-pip vim sudo && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN pip install --upgrade setuptools pip && rm -rf ~/.cache/pip
RUN useradd -ms /bin/bash -G sudo frappe && printf '# User rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/frappe

#nodejs
RUN curl https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_amd64.deb > node.deb \
 && dpkg -i node.deb \
 && rm node.deb

USER frappe
WORKDIR /home/frappe
RUN git clone -b master https://github.com/frappe/bench.git bench-repo

USER root
RUN pip install -e bench-repo && rm -rf ~/.cache/pip \
  && npm install -g yarn \
  && chown -R frappe:frappe /home/frappe/*

USER frappe
WORKDIR /home/frappe/frappe-bench

RUN bench init frappe-bench --ignore-exist --skip-redis-config-generation
COPY frappe-bench/Procfile Procfile
COPY frappe-bench/sites/common_site_config.json sites/common_site_config.json
COPY redis-conf/redis_cache.conf config/redis_cache.conf
COPY redis-conf/redis_queue.conf config/redis_queue.conf
COPY redis-conf/redis_socketio.conf config/redis_socketio.conf
RUN bench set-mariadb-host mariadb
# RUN bench new-site site1.local
# COPY frappe-bench/add_sites.sh add_sites.sh
# RUN chmod +x add_sites
# USER root
# RUN ./add_sites
# USER frappe