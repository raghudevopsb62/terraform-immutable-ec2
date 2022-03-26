#!/bin/bash

if [ -f /etc/nginx/default.d/roboshop.conf ]; then
  sed -i -e 's/ENV/dev/' /etc/nginx/default.d/roboshop.conf /etc/filebeat/filebeat.yml
  systemctl restart nginx
  systemctl restart filebeat
  exit
fi

COMPONENT=$(ls /home/roboshop/)
sed -i -e 's/ENV/dev/' /etc/systemd/system/${COMPONENT}.service /etc/filebeat/filebeat.yml
systemctl daemon-reload
systemctl restart ${COMPONENT}
systemctl restart filebeat
