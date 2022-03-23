#!/bin/bash

if [ -f /etc/nginx/default.d/roboshop.conf ]; then
  sed -i -e 's/ENV/prod/' /etc/nginx/default.d/roboshop.conf
  systemctl restart nginx
  exit
fi

COMPONENT=$(ls /home/roboshop/)
sed -i -e 's/ENV/prod/' /etc/systemd/system/${COMPONENT}.service
systemctl daemon-reload
systemctl restart ${COMPONENT}
