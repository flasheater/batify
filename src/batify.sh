#!/usr/bin/env bash
#
# The MIT License (MIT)
#
# Copyright (c) 2015-2016 Thomas "Ventto" Venriès <thomas.venries@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
xtty=$(cat /sys/class/tty/tty0/active)
xuser=$(who | grep ${xtty}  | head -n1 | cut -d' ' -f1)

if [ -z "${xuser}" ]; then
    echo "No user found from ${xtty}."
    exit 1
fi

xdisplay=$(ps --no-headers -o command -p $(pgrep Xorg) | \
    grep "vt$(echo $xtty | grep -o "[0-9]")" | \
    grep -o ":[0-9]" | head -n 1)

if [ -z "${xdisplay}" ]; then
    echo "No X process found from ${xtty}."
    exit 1
fi

for pid in $(ps -u ${xuser} -o pid --no-headers); do
    env="/proc/${pid}/environ"
    if [ ! -f "${env}" ] || [ ! -r "${env}" ]; then
        continue
    fi
    display=$(grep -z "^DISPLAY=" ${env} | tr -d '\0' | cut -d '=' -f 2)
    if [ -n "${display}" ]; then
        if [ "${display}" != "${xdisplay}" ]; then
            continue
        fi
        dbus=$(grep -z "DBUS_SESSION_BUS_ADDRESS=" $env | tr -d '\0' | \
            sed 's/DBUS_SESSION_BUS_ADDRESS=//g')
        if [ -n $dbus ]; then
            xauth=$(grep -z "XAUTHORITY=" $env | tr -d '\0' | sed 's/XAUTHORITY=//g')
            break
        fi
    fi
done

[ -z "${dbus}" ]    && echo "No session bus address found."     && exit 1
[ -z "${xauth}" ]   && echo "No Xauthority found."              && exit 1

_udev_params=( "$@" )
_bat_name="${_udev_params[0]}"
_bat_capacity="${_udev_params[1]}"
_bat_plug="${_udev_params[2]}"

icon_dir="/usr/share/icons/batify"
icon_path="${icon_dir}/${icon}.png"

if [ "${_bat_plug}" != "none" ]; then
	if [ "${_bat_plug}" == "1" ]; then
		ntf_lvl="normal"; icon="bat-plug"
		ntf_msg="Power: plugged in"
	else
		ntf_lvl="normal" ; icon="bat-unplug"
		ntf_msg="Power: unplugged"
	fi
else
	case ${_bat_capacity} in
		[0-9])  ntf_lvl="critical"; icon="critical" ;;
		1[0-5]) ntf_lvl="low";      icon="low"      ;;
		*) exit ;;
	esac
	ntf_msg="[${_bat_name}] - Battery: ${_bat_capacity}%"
fi

[ -f /usr/bin/su ]  && su_path="/usr/bin/su"
[ -f /bin/su ]      && su_path="/bin/su" || su_path=

[ -z "$su_path" ]   && echo "'su' command not found." && exit 1

DBUS_SESSION_BUS_ADDRESS=$dbus DISPLAY=$xdisplay XAUTHORITY=$xauth \
${su_path} ${xuser} -c \
"/usr/bin/notify-send --hint=int:transient:1 -u ${ntf_lvl} -i \"${icon_path}\" \"${ntf_msg}\""
