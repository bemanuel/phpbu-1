#!/bin/sh

tzupdate ${tz:+"-t$tz"}

/usr/local/bin/phpbu "$@"
