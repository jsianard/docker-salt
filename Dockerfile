FROM cloudlab/ubuntu

ENV SERVICE postfix
ENV ROLE server
ENV RECLASS_URL https://github.com/tcpcloud/workshop-salt-model.git
ENV RECLASS_BRANCH docker

ENV DEBIAN_FRONTEND noninteractive
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/service

RUN apt-get update
RUN apt-get install -y salt-minion reclass git

## Salt
RUN apt-get install -y salt-formula-${SERVICE}
ADD files/minion.conf /etc/salt/minion
RUN test -d /etc/salt/minion.d || mkdir /etc/salt/minion.d
RUN echo "id: \${SERVICE}.\${ROLE}\nmaster: localhost" > /etc/salt/minion.d/minion.conf

## Reclass
RUN test -d /etc/reclass || mkdir /etc/reclass
ADD files/reclass-config.yml /etc/reclass/reclass-config.yml

RUN git clone ${RECLASS_URL} /srv/salt/reclass -b ${RECLASS_BRANCH}
RUN ln -s /usr/share/salt-formulas/reclass/service /srv/salt/reclass/classes/service

## Application
RUN salt-call --id=${SERVICE}.${ROLE} --local --retcode-passthrough pillar.data
RUN salt-call --id=${SERVICE}.${ROLE} --local --retcode-passthrough state.sls ${SERVICE}

ADD files/entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh

## Cleanup
RUN apt-get purge -y salt-master salt-minion reclass git salt-formula-*
RUN apt-get autoremove --purge -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /srv/salt /etc/salt