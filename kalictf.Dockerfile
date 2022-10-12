# Pull latest docker kali image
FROM kalilinux/kali-rolling:latest
LABEL maintainer="Rachel Snyder <zizzixsec@gmail.com>"

#ARGS
ARG CTFUSER="ctf"
ARG CTFPASS="ctf"

# Environment Variables
ENV DEBIAN_FRONTEND noninteractive
ENV TZ America/Chicago
ENV USER ${CTFUSER}
ENV SHELL "/bin/bash"
ENV HOME "/home/${CTFUSER}"

# Install base packages
RUN apt update && \
  apt install -y \
    netcat-traditional \
    kali-desktop-xfce \
    build-essential \
    python-is-python3 \
    python3-pip \
    python3-dev \
    default-jdk \
    default-jre \
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
    xrdp --fix-missing && \
    apt -qy autoremove && \
    apt clean && \
    rm -rf /var/lib/apt/list/*

# Fix timezone
RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
  dpkg-reconfigure -f noninteractive tzdata

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen  

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
RUN useradd -m -d ${HOME} -s ${SHELL} -G sudo ${CTFUSER} && \
  echo "${CTFUSER}:${CTFPASS}" | chpasswd

RUN chown -R ${CTFUSER}:${CTFUSER} ${HOME}

# User setup and linking of the ctf directory
USER ${CTFUSER}
WORKDIR ${HOME}

RUN ln -s /mnt/ctfs ctfs && \
  ln -s /mnt/tools tools

# Setup VIM
RUN echo '\
set number\n\
set smartindent\n\
set tabstop=4\n\
set shiftwidth=4\n\
set expandtab\n\
' >> ${HOME}/.vimrc

RUN echo '\
export PYTHONIOENCODING=UTF-8 \
export LC_ALL=en_US.UTF-8 \
export LANG=en_US.UTF-8 \  
export LANGUAGE=en_US \
' >> ${HOME}/.bashrc

RUN echo '\
source /pwndbg/gdbinit.py \
' >> ${HOME}/.gdbinit

ENTRYPOINT [ "/bin/bash" ]
