# Pull latest docker kali image
FROM kalilinux/kali-rolling:latest
LABEL maintainer="Rachel Snyder <zizzixsec@gmail.com>"

#ARGS
ARG CTFUSER="ctf"
ARG CTFPASS="ctf"
ARG CTFID="1000"

# Environment Variables
ENV DEBIAN_FRONTEND noninteractive
ENV TZ America/Chicago
ENV SHELL "/bin/zsh"
ENV HOME "/home/${CTFUSER}"

# Install base packages
RUN dpkg --add-architecture i386 && \
  apt update && \
  apt install -y \
    netcat-traditional \
    kali-desktop-xfce \
    build-essential \
    python-is-python3 \
    python3-pip \
    python3-dev \
    default-jdk \
    default-jre \
    lib32z1 \
    iputils-ping \
    libssl-dev \
    libffi-dev \
    socat \
    seclists \
    wordlists \
    gobuster \
    burpsuite \
    patchelf \
    elfutils \
    strace \
    ltrace \
    locales \
    tzdata \
    cargo \
    ruby \
    ruby-dev \
    wget \
    curl \
    nasm \
    vim \
    git \
    tmux \
    file \
    xorg \
    xrdp \
    zsh --fix-missing && \
    apt -qy autoremove && \
    apt clean && \
    rm -rf /var/lib/apt/list/*

# Fix timezone
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
  dpkg-reconfigure -f noninteractive tzdata

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8  

# Python modules
RUN python3 -m pip install -U pip && \
  python3 -m pip install --no-cache-dir \
    ropgadget \
    pip \
    pwntools \
    pycryptodome \
    ropper \
    capstone

# Ruby modules 
RUN gem install one_gadget seccomp-tools && \
  rm -rf /var/lib/gems/2.*/cache/*

# Install pwngdb
RUN git clone --depth 1 https://github.com/pwndbg/pwndbg && \
  cd pwndbg && chmod +x setup.sh && ./setup.sh

# Install pwninit
RUN wget https://github.com/io12/pwninit/releases/download/3.2.0/pwninit && \
  mv ./pwninit /usr/local/bin/.  && \
  chmod +x /usr/local/bin/pwninit

# Setup and run xrdp
RUN sed -i "\
  s/port=3389/port=3390/g \
" /etc/xrdp/xrdp.ini

# Disable root login and syslog logging for xrdp-sesman
RUN sed -i "\
  s/AllowRootLogin=true/AllowRootLogin=false/g; \
  s/EnableSyslog=1/EnableSyslog=0/g \
" /etc/xrdp/sesman.ini

RUN ln -sf /dev/stdout /var/log/xrdp.log
RUN ln -sf /dev/stdout /var/log/xrdp-sesman.log

# Disable root login
RUN chsh -s /usr/sbin/nologin root

# Setup the CTF user
RUN addgroup --gid ${CTFID} ${CTFUSER} && \
  useradd -m -d ${HOME} -s ${SHELL} --uid ${CTFID} --gid ${CTFID} -G sudo ${CTFUSER} && \
  echo "${CTFUSER}:${CTFPASS}" | chpasswd

# Fix static directory and home folder permissions
RUN chown -R root:${CTFID} ${HOME}

# User setup and linking of the ctf directory
USER ${CTFUSER}
WORKDIR ${HOME}

# Setup VIM
RUN echo '\
set number\n\
set smartindent\n\
set tabstop=4\n\
set shiftwidth=4\n\
set expandtab\n\
' >> ${HOME}/.vimrc

ENTRYPOINT [ "/bin/bash" ]
