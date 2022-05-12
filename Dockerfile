FROM --platform=amd64 ubuntu:20.04

ENV MAPR_UID 5000
ENV MAPR_GID 5000
ENV MAPR_USER mapr
ENV MAPR_PASS mapr
ENV MAPR_PWD mapr
ENV MAPR_GROUP mapr
ENV MAPR_USER_HOME /home/mapr
ENV MAPR_MOUNT_PATH /mapr
ENV MAPR_DATA_PATH /data
ENV MAPR_HOST maprdemo.mapr.io 
ENV MAPR_CLUSTER maprdemo.mapr.io
ENV PORTS '-p 8580:8580 -p 8998:8998 -p 9998:9998 -p 8042:8042 -p 8888:8888 -p 9997:9997 -p 10001:10001 -p 8190:8190 -p 8243:8243 -p 2222:22 -p 4040:4040 -p 7221:7221 -p 8090:8090 -p 5660:5660 -p 8443:8443 -p 19888:19888 -p 50060:50060 -p 18080:18080 -p 8032:8032 -p 14000:14000 -p 19890:19890 -p 10000:10000 -p 11443:11443 -p 12000:12000 -p 8081:8081 -p 8002:8002 -p 8080:8080 -p 31010:31010 -p 8044:8044 -p 8047:8047 -p 11000:11000 -p 2049:2049 -p 8188:8188 -p 7077:7077 -p 7222:7222 -p 5181:5181 -p 5661:5661 -p 5692:5692 -p 5724:5724 -p 5756:5756 -p 10020:10020 -p 50000-50050:50000-50050 -p 9001:9001 -p 5693:5693 -p 9002:9002 -p 31011:31011 -p 5678:5678 -p 8082:8082 -p 8087:8087 -p 8780:8780 -p 8793:8793 -p 9083:9083 -p 50111:50111'

ENV container docker
ENV DEBIAN_FRONTEND=noninteractive

## From: https://github.com/robertdebock/docker-ubuntu-systemd
RUN apt update -y
RUN apt install -y systemd systemd-sysv; apt clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
    cd /lib/systemd/system/sysinit.target.wants/ ; \
    ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1 ; \
    rm -f /lib/systemd/system/multi-user.target.wants/* ; \
    rm -f /etc/systemd/system/*.wants/* ; \
    rm -f /lib/systemd/system/local-fs.target.wants/* ; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev* ; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl* ; \
    rm -f /lib/systemd/system/basic.target.wants/* ; \
    rm -f /lib/systemd/system/anaconda.target.wants/* ; \
    rm -f /lib/systemd/system/plymouth* ; \
    rm -f /lib/systemd/system/systemd-update-utmp*

## Core packages
RUN apt update -y; apt install -y ca-certificates locales syslinux syslinux-utils

ENV SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
RUN locale-gen $LC_ALL

## Extra packages
RUN apt install -y --no-install-recommends gnupg2 curl wget openjdk-11-jdk iproute2 \
    default-jdk openssh-server openssh-client file tar python net-tools iputils-ping \
    iputils-arping iputils-tracepath sudo wamerican lsb-release apt-utils rpcbind \
    nfs-common vim cron

RUN sed -i 's/#PasswordAuthentication/PasswordAuthentication/' /etc/ssh/sshd_config; \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config; \
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd; \
    /usr/bin/ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa; \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys 

## Enable mapr repository
RUN curl -k https://package.mapr.hpe.com/releases/pub/maprgpg.key | apt-key add -
RUN echo 'deb https://package.mapr.hpe.com/releases/v7.0.0/ubuntu binary bionic' >> /etc/apt/sources.list
RUN echo 'deb https://package.mapr.hpe.com/releases/MEP/MEP-8.1.0/ubuntu binary bionic' >> /etc/apt/sources.list
RUN apt update -y; apt upgrade -y

RUN apt install -y mapr-fileserver \
    mapr-client \
    mapr-cldb \
    mapr-zookeeper \
    mapr-mastgateway \
    mapr-nfs \
    mapr-webserver \
    mapr-apiserver \
    mapr-s3server \
    mapr-gateway \
    mapr-posix-client-basic

RUN groupadd -g ${MAPR_GID} ${MAPR_GROUP} && useradd -m -u ${MAPR_UID} -g ${MAPR_GID} -d ${MAPR_USER_HOME} -s /bin/bash ${MAPR_USER} && usermod -a -G sudo ${MAPR_GROUP}
RUN echo "root:${MAPR_PASS}" | chpasswd 
RUN echo "${MAPR_USER}:${MAPR_PASS}" | chpasswd 
RUN sed -i 's!/proc/meminfo!/opt/mapr/conf/meminfofake!' /opt/mapr/server/initscripts-common.sh    

RUN mkdir ${MAPR_MOUNT_PATH}
RUN mkdir ${MAPR_DATA_PATH}

COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 8580 8998 9998 8042 8888 9997 10001 8190 8243 22 4040 7221 8090 5660 8443 19888 50060 18080 8032 14000 19890 10000 11443 12000 8081 8002 8080 31010 8044 8047 11000 2049 8188 7077 7222 5181 5661 5692 5724 5756 10020 50000-50050 9001 5693 9002 31011 5678 8082 8087 8780 8793 9083 50111

CMD /run.sh

# Run with
# docker run -it --rm --device /dev/fuse --cap-add SYS_ADMIN -p 8580:8580 -p 8998:8998 -p 9998:9998 -p 8042:8042 -p 8888:8888 -p 9997:9997 -p 10001:10001 -p 8190:8190 -p 8243:8243 -p 2222:22 -p 4040:4040 -p 7221:7221 -p 8090:8090 -p 5660:5660 -p 8443:8443 -p 19888:19888 -p 50060:50060 -p 18080:18080 -p 8032:8032 -p 14000:14000 -p 19890:19890 -p 10000:10000 -p 11443:11443 -p 12000:12000 -p 8081:8081 -p 8002:8002 -p 8080:8080 -p 31010:31010 -p 8044:8044 -p 8047:8047 -p 11000:11000 -p 2049:2049 -p 8188:8188 -p 7077:7077 -p 7222:7222 -p 5181:5181 -p 5661:5661 -p 5692:5692 -p 5724:5724 -p 5756:5756 -p 10020:10020 -p 50000-50050:50000-50050 -p 9001:9001 -p 5693:5693 -p 9002:9002 -p 31011:31011 -p 5678:5678 -p 8082:8082 -p 8087:8087 -p 8780:8780 -p 8793:8793 -p 9083:9083 -p 50111:50111 --platform linux/amd64 erdincka/mapr
# connect with ssh -p 2222 root@localhost

# ENTRYPOINT /usr/bin/init-script