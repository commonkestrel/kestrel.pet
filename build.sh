#! /bin/bash

/home/linuxbrew/.linuxbrew/bin/gleam export erlang-shipment
systemctl restart passerine.service
