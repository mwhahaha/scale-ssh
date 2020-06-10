FROM centos:8
LABEL maintainer="Alex Schultz <aschultz@redhat.com>"

RUN yum install -y openssh-server && yum clean all && rm -rf /var/cache/yum

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

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
