# vim: set filetype=dockerfile :
FROM ubuntu:14.04

# Install git 2.4.1
RUN apt-get update \
  && apt-get install -y software-properties-common \
  && apt-add-repository -y ppa:git-core/ppa \
  && apt-get update \
  && apt-get install -y \
    git=1:2.4.1-0ppa1~ubuntu14.04* \
  && apt-get clean autoclean \
  && apt-get autoremove -y --purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Install some utilities I need
RUN apt-get update \
  && apt-get install -y \
    python \
    curl \
    vim \
    strace \
    diffstat \
    pkg-config \
    cmake \
    build-essential \
    tcpdump \
    mercurial \
    wget \
    host \
    dnsutils \
    tree \
    dos2unix \
    zip \
    bash-completion \
  && apt-get clean autoclean \
  && apt-get autoremove -y --purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Configure timezone and locale
RUN echo "America/Toronto" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata
RUN export LANGUAGE=en_US.UTF-8; export LANG=en_US.UTF-8; export LC_ALL=en_US.UTF-8; locale-gen en_US.UTF-8; DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

# Install go
RUN curl https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz | tar -C /usr/local -zx
ENV GOROOT /usr/local/go
ENV PATH /usr/local/go/bin:$PATH

# Install fleetctl to /usr/local/bin
RUN mkdir -p /tmp/fleetctl \
  && cd /tmp/fleetctl \
  && wget https://github.com/coreos/fleet/releases/download/v0.10.1/fleet-v0.10.1-linux-amd64.tar.gz \
  && tar -zxvf fleet-v0.10.1-linux-amd64.tar.gz \
  && mv fleet-v0.10.1-linux-amd64/fleetctl /usr/local/bin \
  && cd /tmp \
  && rm -rf fleetctl

# Setup home environment
RUN useradd dev
RUN echo "dev ALL = NOPASSWD: ALL" > /etc/sudoers.d/00-dev
RUN mkdir /home/dev && chown -R dev: /home/dev
RUN mkdir -p /home/dev/go/src /home/dev/bin /home/dev/lib /home/dev/include /home/dev/tmp
ENV PATH /home/dev/bin:$PATH
ENV PKG_CONFIG_PATH /home/dev/lib/pkgconfig
ENV LD_LIBRARY_PATH /home/dev/lib
ENV GOPATH /home/dev/go
ENV PATH $GOPATH/bin:$PATH

# Build & Install terraform
RUN git clone https://github.com/hashicorp/terraform.git $GOPATH/src/github.com/hashicorp/terraform && \
  cd $GOPATH/src/github.com/hashicorp/terraform && \
  XC_OS=linux XC_ARCH=amd64 make updatedeps bin

# Install jekyll + dependencies
RUN apt-get update \
  && apt-get install -y software-properties-common \
  && apt-add-repository -y ppa:brightbox/ruby-ng \
  && apt-get update \
  && apt-get install -y \
  ruby2.2 \
  ruby2.2-dev \
  && gem install --no-document bundler \
  && apt-get clean \
  && apt-get autoremove -y --purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install keybase + related
RUN apt-get update \
  && apt-get install -y \
  nodejs-legacy \
  npm \
  && npm install -g keybase-installer \
  && /usr/local/bin/keybase-installer \
  && apt-get clean \
  && apt-get autoremove -y --purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install ledger
RUN apt-get install -y software-properties-common \
  && apt-add-repository -y ppa:mbudde/ledger \
  && apt-get update \
  && apt-get install -y ledger \
  && apt-get clean \
  && apt-get autoremove -y --purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create a tmux wrapper to work around
# https://github.com/docker/docker/issues/8755
RUN touch /home/dev/bin/tmux \
  && chown dev: /home/dev/bin/tmux \
  && chmod +x /home/dev/bin/tmux \
  && echo -ne '#!'"/bin/bash\n/usr/bin/script -c /usr/bin/tmux /dev/null" > /home/dev/bin/tmux

# Install docker
RUN wget -O /tmp/docker.sh https://get.docker.com/ \
  && /bin/sh /tmp/docker.sh \
  && usermod -aG docker dev \
  && apt-get clean \
  && apt-get autoremove -y --purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install the wercker cli
RUN wget -O /tmp/wercker.sh https://install.wercker.com \
  && /bin/sh /tmp/wercker.sh \
  && apt-get clean \
  && apt-get autoremove -y --purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create a shared data volume
# We need to create an empty file, otherwise the volume will
# belong to root.
# This is probably a Docker bug.
RUN mkdir /var/shared/
RUN touch /var/shared/placeholder
RUN chown -R dev:dev /var/shared
VOLUME /var/shared

# Link in shared parts of the home directory
WORKDIR /home/dev
ENV HOME /home/dev
run ln -s /var/shared/.ssh
run ln -s /var/shared/.bash_logout
run ln -s /var/shared/.bash_profile
run ln -s /var/shared/.bashrc
run ln -s /var/shared/.gitconfig
run ln -s /var/shared/.gitignore_global
run ln -s /var/shared/.profile
run ln -s /var/shared/.tmux.conf
run ln -s /var/shared/.vim
run ln -s /var/shared/.vimrc
run ln -s /var/shared/Dropbox/freshbooks
run ln -s /var/shared/Dropbox/projects
run ln -s /var/shared/Dropbox/gnupg .gnupg

RUN chown -R dev: /home/dev
USER dev

ENTRYPOINT "/bin/bash"
