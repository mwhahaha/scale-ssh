FROM registry.centos.org/centos:latest
LABEL maintainer="Alex Schultz <aschultz@redhat.com>"

RUN yum -y update && yum -y install openssh-server passwd && yum clean all
#RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N "" && ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N "" && ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ""
#RUN useradd foobar && echo "foobar:foobar" | chpasswd
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# SSH login fix. Otherwise user is kicked off after login
#RUN sed 's@#\?PermitEmptyPasswords no@PermitEmptyPasswords yes@g' -i /etc/ssh/sshd_config

# create root .ssh dir
RUN mkdir -p /root/.ssh && \
    chmod o-rwx /root/.ssh

EXPOSE 22

# pull in tini so container life cycle works correctly (e.g. stop)
# https://github.com/krallin/tini/
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "-g", "--"]

# start.sh will auto generate a key if necessary
COPY start.sh /
RUN chmod 0755 /start.sh

# start ssh
CMD /start.sh
